#!/bin/bash

# Test CORS Reliability - Multiple requests untuk test konsistensi
# Script untuk test apakah CORS handling konsisten

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_URL="http://54.179.2.8:4001"
BACKEND_URL="http://54.179.2.8:4002"
LOGIN_URL="${BACKEND_URL}/api/auth/login"
TEST_COUNT=10

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔄 Testing CORS Reliability - ${TEST_COUNT} requests"
echo "=================================================="

# Counters
success_count=0
failure_count=0
cors_success=0
cors_failure=0

# Test function
test_cors_request() {
    local test_num=$1
    local origin=$2
    
    print_status "Test ${test_num}: CORS request from ${origin}"
    
    # Test preflight request
    local preflight_response=$(curl -s -X OPTIONS \
        -H "Origin: ${origin}" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        -w "%{http_code}" \
        "${LOGIN_URL}" 2>/dev/null)
    
    local preflight_code="${preflight_response: -3}"
    
    if [ "$preflight_code" = "200" ]; then
        print_success "Preflight OK (${preflight_code})"
        ((cors_success++))
    else
        print_error "Preflight FAILED (${preflight_code})"
        ((cors_failure++))
        return 1
    fi
    
    # Test actual login request
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Origin: ${origin}" \
        -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
        -w "%{http_code}" \
        "${LOGIN_URL}" 2>/dev/null)
    
    local login_code="${login_response: -3}"
    local login_body="${login_response%???}"
    
    if [ "$login_code" = "200" ] && echo "$login_body" | grep -q "token"; then
        print_success "Login OK (${login_code})"
        ((success_count++))
    else
        print_error "Login FAILED (${login_code})"
        echo "Response: $login_body"
        ((failure_count++))
    fi
    
    echo "---"
}

# Run multiple tests
print_status "Starting ${TEST_COUNT} CORS reliability tests..."

for i in $(seq 1 $TEST_COUNT); do
    test_cors_request $i "$FRONTEND_URL"
    sleep 1  # Small delay between requests
done

# Test with different origins
print_status "Testing with different origins..."

test_cors_request $((TEST_COUNT + 1)) "http://localhost:3000"
test_cors_request $((TEST_COUNT + 2)) "http://localhost:3001"
test_cors_request $((TEST_COUNT + 3)) "http://54.179.2.8:3000"

# Results summary
echo ""
print_status "CORS Reliability Test Results:"
echo "===================================="
echo "Total Tests: $((TEST_COUNT + 3))"
echo "Successful Logins: $success_count"
echo "Failed Logins: $failure_count"
echo "Successful CORS: $cors_success"
echo "Failed CORS: $cors_failure"

# Calculate percentages
if [ $((success_count + failure_count)) -gt 0 ]; then
    success_rate=$((success_count * 100 / (success_count + failure_count)))
    echo "Login Success Rate: ${success_rate}%"
fi

if [ $((cors_success + cors_failure)) -gt 0 ]; then
    cors_rate=$((cors_success * 100 / (cors_success + cors_failure)))
    echo "CORS Success Rate: ${cors_rate}%"
fi

# Determine reliability
if [ $success_count -eq $((TEST_COUNT + 3)) ]; then
    print_success "CORS is 100% reliable! ✅"
elif [ $success_count -gt $((TEST_COUNT + 1)) ]; then
    print_warning "CORS is mostly reliable (${success_rate}%) ⚠️"
else
    print_error "CORS is unreliable (${success_rate}%) ❌"
fi

# Additional debugging
echo ""
print_status "Debugging Information:"
echo "=========================="

# Check server logs
print_status "Recent server logs (last 10 lines):"
if command -v docker >/dev/null 2>&1; then
    docker logs starhub-express --tail 10 2>/dev/null || echo "Could not fetch server logs"
else
    echo "Docker not available for log checking"
fi

# Test server response time
print_status "Testing server response time..."
response_time=$(curl -s -o /dev/null -w "%{time_total}" "${LOGIN_URL}")
echo "Server response time: ${response_time}s"

if (( $(echo "$response_time > 2.0" | bc -l) )); then
    print_warning "Server response time is slow (${response_time}s)"
fi

echo ""
print_status "Recommendations:"
echo "==================="
if [ $failure_count -gt 0 ]; then
    echo "1. Check server logs for CORS errors"
    echo "2. Verify ALLOWED_ORIGINS environment variable"
    echo "3. Restart server if needed"
    echo "4. Check for race conditions in CORS middleware"
fi

if [ $cors_failure -gt 0 ]; then
    echo "5. Check preflight request handling"
    echo "6. Verify CORS headers are set correctly"
fi
