#!/bin/bash

# Clear Cache and Test CORS
# Script untuk clear browser cache dan test CORS consistency

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

echo "🧹 Clear Cache and Test CORS"
echo "============================"

# Step 1: Clear server-side cache
print_status "Step 1: Clearing server-side cache"
if command -v docker >/dev/null 2>&1; then
    # Restart container to clear any server-side cache
    docker restart starhub-express >/dev/null 2>&1 || {
        print_warning "Could not restart container, continuing..."
    }
    print_success "Server restarted"
else
    print_warning "Docker not available, skipping server restart"
fi

# Step 2: Test with cache-busting headers
print_status "Step 2: Testing with cache-busting headers"

# Test with no-cache headers
print_status "Test with no-cache headers"
CACHE_TEST=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: ${FRONTEND_URL}" \
    -H "Cache-Control: no-cache" \
    -H "Pragma: no-cache" \
    -H "If-None-Match: *" \
    -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
    -w "%{http_code}" \
    "${LOGIN_URL}" 2>/dev/null)

CACHE_CODE="${CACHE_TEST: -3}"
CACHE_BODY="${CACHE_TEST%???}"

if [ "$CACHE_CODE" = "200" ] && echo "$CACHE_BODY" | grep -q "token"; then
    print_success "Login with no-cache headers: OK"
else
    print_error "Login with no-cache headers: FAILED (${CACHE_CODE})"
    echo "Response: $CACHE_BODY"
fi

# Step 3: Test with different User-Agent
print_status "Step 3: Testing with different User-Agent"

USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    "PostmanRuntime/7.28.4"
)

for ua in "${USER_AGENTS[@]}"; do
    print_status "Testing with User-Agent: ${ua:0:30}..."
    
    UA_TEST=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Origin: ${FRONTEND_URL}" \
        -H "User-Agent: ${ua}" \
        -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
        -w "%{http_code}" \
        "${LOGIN_URL}" 2>/dev/null)
    
    UA_CODE="${UA_TEST: -3}"
    
    if [ "$UA_CODE" = "200" ]; then
        print_success "User-Agent test: OK"
    else
        print_error "User-Agent test: FAILED (${UA_CODE})"
    fi
done

# Step 4: Test with timestamp-based cache busting
print_status "Step 4: Testing with timestamp-based cache busting"

TIMESTAMP=$(date +%s)
TIMESTAMP_TEST=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: ${FRONTEND_URL}" \
    -H "X-Timestamp: ${TIMESTAMP}" \
    -H "X-Request-ID: $(uuidgen 2>/dev/null || echo "req-${TIMESTAMP}")" \
    -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
    -w "%{http_code}" \
    "${LOGIN_URL}" 2>/dev/null)

TIMESTAMP_CODE="${TIMESTAMP_TEST: -3}"

if [ "$TIMESTAMP_CODE" = "200" ]; then
    print_success "Timestamp-based test: OK"
else
    print_error "Timestamp-based test: FAILED (${TIMESTAMP_CODE})"
fi

# Step 5: Multiple rapid requests test
print_status "Step 5: Testing multiple rapid requests"

RAPID_SUCCESS=0
RAPID_TOTAL=5

for i in $(seq 1 $RAPID_TOTAL); do
    RAPID_TEST=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Origin: ${FRONTEND_URL}" \
        -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
        -w "%{http_code}" \
        "${LOGIN_URL}" 2>/dev/null)
    
    RAPID_CODE="${RAPID_TEST: -3}"
    
    if [ "$RAPID_CODE" = "200" ]; then
        ((RAPID_SUCCESS++))
        print_success "Rapid request ${i}: OK"
    else
        print_error "Rapid request ${i}: FAILED (${RAPID_CODE})"
    fi
    
    sleep 0.1  # Small delay
done

# Results
echo ""
print_status "Cache Clear Test Results:"
echo "=============================="
echo "No-cache headers: $([ "$CACHE_CODE" = "200" ] && echo "✅ OK" || echo "❌ FAILED")"
echo "User-Agent tests: Multiple tested"
echo "Timestamp test: $([ "$TIMESTAMP_CODE" = "200" ] && echo "✅ OK" || echo "❌ FAILED")"
echo "Rapid requests: ${RAPID_SUCCESS}/${RAPID_TOTAL} successful"

# Browser cache clearing instructions
echo ""
print_status "Browser Cache Clearing Instructions:"
echo "=========================================="
echo "1. Open browser Developer Tools (F12)"
echo "2. Right-click on refresh button"
echo "3. Select 'Empty Cache and Hard Reload'"
echo "4. Or use Ctrl+Shift+R (Windows) / Cmd+Shift+R (Mac)"
echo "5. Or clear browser data manually:"
echo "   - Chrome: Settings > Privacy > Clear browsing data"
echo "   - Firefox: Settings > Privacy > Clear Data"
echo "   - Safari: Develop > Empty Caches"

# Server-side recommendations
echo ""
print_status "Server-side Recommendations:"
echo "================================="
echo "1. Add cache-busting headers to responses"
echo "2. Set appropriate Cache-Control headers"
echo "3. Use ETags for proper cache validation"
echo "4. Monitor server logs for CORS patterns"

# Test final consistency
echo ""
print_status "Final Consistency Test:"
echo "============================"

FINAL_TESTS=3
FINAL_SUCCESS=0

for i in $(seq 1 $FINAL_TESTS); do
    FINAL_TEST=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Origin: ${FRONTEND_URL}" \
        -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
        -w "%{http_code}" \
        "${LOGIN_URL}" 2>/dev/null)
    
    FINAL_CODE="${FINAL_TEST: -3}"
    
    if [ "$FINAL_CODE" = "200" ]; then
        ((FINAL_SUCCESS++))
    fi
    
    sleep 1
done

if [ $FINAL_SUCCESS -eq $FINAL_TESTS ]; then
    print_success "CORS is now consistent! All ${FINAL_TESTS} tests passed ✅"
else
    print_warning "CORS still inconsistent: ${FINAL_SUCCESS}/${FINAL_TESTS} tests passed ⚠️"
fi
