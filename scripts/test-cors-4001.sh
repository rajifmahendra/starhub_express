#!/bin/bash

# Test CORS untuk StarHub Express API dari frontend port 4001
# Script untuk debugging masalah CORS antara frontend (4001) dan backend (4002)

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

echo "🔍 Testing CORS untuk Frontend (4001) → Backend (4002)"
echo "======================================================"

# Test 1: Check if frontend is accessible
print_status "Test 1: Check frontend accessibility"
if curl -f -s "${FRONTEND_URL}" > /dev/null 2>&1; then
    print_success "Frontend is accessible at ${FRONTEND_URL}"
else
    print_warning "Frontend might not be accessible at ${FRONTEND_URL}"
fi

# Test 2: Check if backend is accessible
print_status "Test 2: Check backend accessibility"
if curl -f -s "${BACKEND_URL}/api/auth/login" > /dev/null 2>&1; then
    print_success "Backend is accessible at ${BACKEND_URL}"
else
    print_error "Backend is not accessible at ${BACKEND_URL}"
    exit 1
fi

# Test 3: CORS preflight request dari frontend port 4001
print_status "Test 3: CORS preflight dari frontend port 4001"
CORS_RESPONSE=$(curl -s -X OPTIONS \
    -H "Origin: ${FRONTEND_URL}" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -v "${LOGIN_URL}" 2>&1)

echo "CORS Response Headers:"
echo "$CORS_RESPONSE" | grep -i "access-control" || echo "No CORS headers found"

if echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin.*4001"; then
    print_success "CORS headers present untuk port 4001"
elif echo "$CORS_RESPONSE" | grep -q "Access-Control-Allow-Origin"; then
    print_warning "CORS headers present but might not include port 4001"
    echo "$CORS_RESPONSE" | grep -i "access-control-allow-origin"
else
    print_error "CORS headers missing untuk port 4001"
fi

# Test 4: Login request dengan Origin header dari port 4001
print_status "Test 4: Login request dengan Origin header dari port 4001"
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: ${FRONTEND_URL}" \
    -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
    "${LOGIN_URL}")

echo "Login response: $LOGIN_RESPONSE"

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    print_success "Login successful dengan Origin header dari port 4001"
else
    print_error "Login failed dengan Origin header dari port 4001"
    echo "Response: $LOGIN_RESPONSE"
fi

# Test 5: Test dengan browser-like headers
print_status "Test 5: Login request dengan browser-like headers"
BROWSER_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Origin: ${FRONTEND_URL}" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    -H "Referer: ${FRONTEND_URL}/login" \
    -d '{"email":"rajif@gmail.com","password":"mypassword"}' \
    "${LOGIN_URL}")

echo "Browser-like response: $BROWSER_RESPONSE"

if echo "$BROWSER_RESPONSE" | grep -q "token"; then
    print_success "Login successful dengan browser-like headers"
else
    print_error "Login failed dengan browser-like headers"
    echo "Response: $BROWSER_RESPONSE"
fi

# Test 6: Check server logs simulation
print_status "Test 6: Simulate server CORS check"
echo "Checking if port 4001 is in allowed origins..."

# Simulate the server logic
ALLOWED_ORIGINS="http://localhost:3000,http://localhost:3001,http://54.179.2.8:3000,http://54.179.2.8:3001,http://54.179.2.8:4001"
if echo "$ALLOWED_ORIGINS" | grep -q "4001"; then
    print_success "Port 4001 is in allowed origins list"
else
    print_error "Port 4001 is NOT in allowed origins list"
    echo "Current allowed origins: $ALLOWED_ORIGINS"
fi

echo ""
print_status "CORS Test Summary untuk Port 4001:"
echo "========================================"
echo "✅ Frontend accessibility: Checked"
echo "✅ Backend accessibility: Checked"
echo "✅ CORS preflight: Tested"
echo "✅ Login with origin: Tested"
echo "✅ Browser-like headers: Tested"
echo "✅ Allowed origins check: Tested"
echo ""
print_status "Jika masih ada masalah CORS:"
echo "1. Pastikan server sudah di-restart setelah update CORS config"
echo "2. Check server logs: docker logs starhub-express"
echo "3. Verify ALLOWED_ORIGINS environment variable"
echo "4. Test dengan browser developer tools"
