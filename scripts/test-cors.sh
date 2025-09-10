#!/bin/bash

# Test CORS untuk StarHub Express API
# Script untuk debugging masalah CORS setelah deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE="http://54.179.2.8:4002"
LOGIN_URL="${API_BASE}/api/auth/login"

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

echo "🔍 Testing CORS untuk StarHub Express API"
echo "=========================================="

# Test 1: Basic connectivity
print_status "Test 1: Basic connectivity"
if curl -f -s "${API_BASE}/api/auth/login" > /dev/null 2>&1; then
    print_success "API is reachable"
else
    print_error "API is not reachable"
    exit 1
fi

# Test 2: CORS preflight request dari localhost:3000
print_status "Test 2: CORS preflight dari localhost:3000"
CORS_RESPONSE=$(curl -s -X OPTIONS \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -v "${LOGIN_URL}" 2>&1)

if echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin"; then
    print_success "CORS headers present untuk localhost:3000"
    echo "$CORS_RESPONSE" | grep -i "access-control-allow-origin"
else
    print_warning "CORS headers missing untuk localhost:3000"
fi

# Test 3: CORS preflight request dari 54.179.2.8:3000
print_status "Test 3: CORS preflight dari 54.179.2.8:3000"
CORS_RESPONSE2=$(curl -s -X OPTIONS \
    -H "Origin: http://54.179.2.8:3000" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -v "${LOGIN_URL}" 2>&1)

if echo "$CORS_RESPONSE2" | grep -q "Access-Control-Allow-Origin"; then
    print_success "CORS headers present untuk 54.179.2.8:3000"
    echo "$CORS_RESPONSE2" | grep -i "access-control-allow-origin"
else
    print_warning "CORS headers missing untuk 54.179.2.8:3000"
fi

# Test 4: Login request dengan Origin header
print_status "Test 4: Login request dengan Origin header"
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: http://localhost:3000" \
    -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
    "${LOGIN_URL}")

echo "Login response: $LOGIN_RESPONSE"

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    print_success "Login successful dengan Origin header"
else
    print_error "Login failed dengan Origin header"
fi

# Test 5: Login request tanpa Origin header
print_status "Test 5: Login request tanpa Origin header"
LOGIN_RESPONSE2=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
    "${LOGIN_URL}")

echo "Login response (no origin): $LOGIN_RESPONSE2"

if echo "$LOGIN_RESPONSE2" | grep -q "token"; then
    print_success "Login successful tanpa Origin header"
else
    print_error "Login failed tanpa Origin header"
fi

echo ""
print_status "CORS Test Summary:"
echo "====================="
echo "✅ API connectivity: OK"
echo "✅ CORS preflight: Checked"
echo "✅ Login with origin: Tested"
echo "✅ Login without origin: Tested"
echo ""
print_status "Jika ada masalah CORS:"
echo "1. Pastikan frontend domain ada di ALLOWED_ORIGINS"
echo "2. Check server logs untuk 'CORS blocked origin'"
echo "3. Set NODE_ENV=development untuk development"
echo "4. Update ALLOWED_ORIGINS environment variable"
