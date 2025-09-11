#!/bin/bash

# Restart StarHub Express dengan konfigurasi CORS yang baru
# Script untuk restart server setelah update CORS configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="starhub-express"
IMAGE_NAME="starhub-express"
IMAGE_TAG="latest"
PORT="4002"

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

echo "🔄 Restarting StarHub Express dengan CORS fix"
echo "============================================="

# Step 1: Stop existing container
print_status "Step 1: Stopping existing container"
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
    print_success "Existing container stopped and removed"
else
    print_warning "No existing container found"
fi

# Step 2: Build new image
print_status "Step 2: Building new Docker image"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . || {
    print_error "Failed to build Docker image"
    exit 1
}
print_success "Docker image built successfully"

# Step 3: Set environment variables
print_status "Step 3: Setting environment variables"
export ALLOWED_ORIGINS="http://localhost:3000,http://localhost:3001,http://54.179.2.8:3000,http://54.179.2.8:3001,http://54.179.2.8:4001"
export NODE_ENV=production

print_success "Environment variables set:"
echo "  ALLOWED_ORIGINS: $ALLOWED_ORIGINS"
echo "  NODE_ENV: $NODE_ENV"

# Step 4: Run new container
print_status "Step 4: Starting new container"
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${PORT}:5000 \
    -e ALLOWED_ORIGINS="$ALLOWED_ORIGINS" \
    -e NODE_ENV="$NODE_ENV" \
    ${IMAGE_NAME}:${IMAGE_TAG} || {
    print_error "Failed to start container"
    exit 1
}
print_success "Container started successfully"

# Step 5: Wait for application to be ready
print_status "Step 5: Waiting for application to be ready"
sleep 10

# Health check
max_attempts=12
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -f http://54.179.2.8:${PORT}/api/auth/login >/dev/null 2>&1; then
        print_success "Application is ready!"
        break
    fi
    
    print_status "Attempt ${attempt}/${max_attempts} - Application not ready yet, waiting..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Application failed to start within expected time"
    print_status "Container logs:"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

# Step 6: Test CORS
print_status "Step 6: Testing CORS configuration"
if command -v ./scripts/test-cors-4001.sh >/dev/null 2>&1; then
    chmod +x scripts/test-cors-4001.sh
    ./scripts/test-cors-4001.sh
else
    print_warning "CORS test script not found, testing manually..."
    
    # Manual CORS test
    CORS_TEST=$(curl -s -X OPTIONS \
        -H "Origin: http://54.179.2.8:4001" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        http://54.179.2.8:${PORT}/api/auth/login 2>&1)
    
    if echo "$CORS_TEST" | grep -q "Access-Control-Allow-Origin"; then
        print_success "CORS headers present"
    else
        print_warning "CORS headers might be missing"
    fi
fi

# Step 7: Show status
print_status "Step 7: Container status"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
print_success "StarHub Express restarted successfully!"
print_status "Backend URL: http://54.179.2.8:${PORT}"
print_status "Frontend URL: http://54.179.2.8:4001"
print_status "CORS configured for port 4001 → 4002"
print_status "Test login from frontend now!"
