#!/bin/bash

# Test CORS dan Authentication untuk StarHub Express API
# Script untuk debugging masalah CORS dan authentication

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
ORDERS_URL="${API_BASE}/api/order"
USERNAME="rajif@gmail.com"
PASSWORD="mypassword"

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

echo "🔍 Testing CORS dan Authentication untuk StarHub Express API"
echo "=============================================================="

# Test 1: Basic connectivity
print_status "Test 1: Basic connectivity to API"
if curl -f -s "${API_BASE}/api/auth/login" > /dev/null 2>&1; then
    print_success "API is reachable"
else
    print_error "API is not reachable"
    exit 1
fi

# Test 2: CORS preflight request
print_status "Test 2: CORS preflight request (OPTIONS)"
CORS_RESPONSE=$(curl -s -X OPTIONS \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -v "${LOGIN_URL}" 2>&1)

if echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin"; then
    print_success "CORS headers present"
    echo "$CORS_RESPONSE" | grep -i "access-control"
else
    print_warning "CORS headers might be missing"
    echo "$CORS_RESPONSE" | grep -i "access-control" || echo "No CORS headers found"
fi

# Test 3: Login request
print_status "Test 3: Login request"
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: http://localhost:3000" \
    -d "{\"email\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    "${LOGIN_URL}")

echo "Login response: $LOGIN_RESPONSE"

# Extract token if login successful
if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    print_success "Login successful, token extracted"
    echo "Token: ${TOKEN:0:20}..."
else
    print_error "Login failed"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

# Test 4: Authenticated request
print_status "Test 4: Authenticated request to orders endpoint"
ORDERS_RESPONSE=$(curl -s -X GET \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Origin: http://localhost:3000" \
    "${ORDERS_URL}")

echo "Orders response: $ORDERS_RESPONSE"

if echo "$ORDERS_RESPONSE" | grep -q "Berhasil mengambil data orders"; then
    print_success "Authenticated request successful"
else
    print_warning "Authenticated request might have issues"
    echo "Response: $ORDERS_RESPONSE"
fi

# Test 5: Test without Origin header (like DAST)
print_status "Test 5: Request without Origin header (DAST simulation)"
DAST_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    "${LOGIN_URL}")

echo "DAST-style response: $DAST_RESPONSE"

if echo "$DAST_RESPONSE" | grep -q "token"; then
    print_success "DAST-style request successful"
else
    print_error "DAST-style request failed"
    echo "Response: $DAST_RESPONSE"
fi

# Test 6: Test with different User-Agent
print_status "Test 6: Request with ZAP User-Agent"
ZAP_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "User-Agent: Mozilla/5.0 (compatible; ZAP)" \
    -d "{\"email\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    "${LOGIN_URL}")

echo "ZAP-style response: $ZAP_RESPONSE"

if echo "$ZAP_RESPONSE" | grep -q "token"; then
    print_success "ZAP-style request successful"
else
    print_error "ZAP-style request failed"
    echo "Response: $ZAP_RESPONSE"
fi

echo ""
print_status "Test Summary:"
echo "==============="
echo "✅ Basic connectivity: OK"
echo "✅ CORS configuration: Checked"
echo "✅ Login authentication: Tested"
echo "✅ Token-based requests: Tested"
echo "✅ DAST compatibility: Tested"
echo ""
print_success "All tests completed!"
print_status "If any tests failed, check server CORS configuration and DAST settings"
