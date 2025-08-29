#!/bin/bash

# StarHub Express DAST Setup Script
# Script untuk mempersiapkan environment DAST testing

set -e

echo "🚀 Setting up DAST environment for StarHub Express..."

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
NETWORK_NAME="dast-network"
SERVER_IP="54.179.2.8"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists curl; then
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    print_success "All prerequisites are met."
}

# Clean up existing resources
cleanup() {
    print_status "Cleaning up existing resources..."
    
    # Stop and remove container
    if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_status "Stopping existing container: ${CONTAINER_NAME}"
        docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
        docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
    fi
    
    # Remove network
    if docker network ls --format 'table {{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
        print_status "Removing existing network: ${NETWORK_NAME}"
        docker network rm ${NETWORK_NAME} >/dev/null 2>&1 || true
    fi
    
    # Clean output directory
    if [ -d "output" ]; then
        print_status "Cleaning output directory"
        rm -rf output
    fi
    mkdir -p output
    
    print_success "Cleanup completed."
}

# Build Docker image
build_image() {
    print_status "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
    
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found in current directory."
        exit 1
    fi
    
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . || {
        print_error "Failed to build Docker image."
        exit 1
    }
    
    print_success "Docker image built successfully."
}

# Setup network
setup_network() {
    print_status "Setting up Docker network: ${NETWORK_NAME}"
    
    docker network create ${NETWORK_NAME} >/dev/null 2>&1 || {
        print_warning "Network ${NETWORK_NAME} might already exist."
    }
    
    print_success "Network setup completed."
}

# Run application
run_application() {
    print_status "Starting application container..."
    
    docker run -d \
        --name ${CONTAINER_NAME} \
        --network ${NETWORK_NAME} \
        -p ${PORT}:5000 \
        -e NODE_ENV=production \
        ${IMAGE_NAME}:${IMAGE_TAG} || {
        print_error "Failed to start application container."
        exit 1
    }
    
    print_success "Application container started."
}

# Wait for application to be ready
wait_for_app() {
    print_status "Waiting for application to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://${SERVER_IP}:${PORT}/api/auth/login >/dev/null 2>&1; then
            print_success "Application is ready!"
            return 0
        fi
        
        print_status "Attempt ${attempt}/${max_attempts} - Application not ready yet, waiting..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "Application failed to start within expected time."
    print_status "Container logs:"
    docker logs ${CONTAINER_NAME}
    exit 1
}

# Test API endpoints
test_endpoints() {
    print_status "Testing API endpoints..."
    
    # Test login endpoint
    if curl -f -X POST http://${SERVER_IP}:${PORT}/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"test@test.com","password":"password"}' >/dev/null 2>&1; then
        print_success "Login endpoint is accessible."
    else
        print_warning "Login endpoint test failed (expected for authentication)."
    fi
    
    # Test health check
    if curl -f http://${SERVER_IP}:${PORT}/api/auth/login >/dev/null 2>&1; then
        print_success "Health check passed."
    else
        print_warning "Health check failed."
    fi
}

# Validate ZAP configuration
validate_config() {
    print_status "Validating ZAP configuration..."
    
    if [ ! -f "expressform.yaml" ]; then
        print_error "expressform.yaml not found."
        exit 1
    fi
    
    # Basic YAML validation
    if command_exists python3; then
        python3 -c "
import yaml
import sys
try:
    with open('expressform.yaml', 'r') as f:
        yaml.safe_load(f)
    print('✅ ZAP configuration is valid YAML')
except Exception as e:
    print(f'❌ ZAP configuration error: {e}')
    sys.exit(1)
" || {
            print_error "ZAP configuration validation failed."
            exit 1
        }
    else
        print_warning "Python3 not available for YAML validation."
    fi
    
    print_success "ZAP configuration validated."
}

# Show status
show_status() {
    print_status "Environment Status:"
    echo ""
    echo "🐳 Container Status:"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "🌐 Network Status:"
    docker network ls --filter "name=${NETWORK_NAME}" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    echo ""
    echo "🔗 Application URLs:"
    echo "  • API Base: http://${SERVER_IP}:${PORT}"
    echo "  • Login: http://${SERVER_IP}:${PORT}/api/auth/login"
    echo "  • Orders: http://${SERVER_IP}:${PORT}/api/order"
    echo "  • Swagger: http://${SERVER_IP}:${PORT}/swagger.json"
    echo ""
    echo "📁 Output Directory: ./output"
    echo ""
}

# Main execution
main() {
    echo "🎯 StarHub Express DAST Setup"
    echo "================================"
    
    check_prerequisites
    cleanup
    validate_config
    build_image
    setup_network
    run_application
    wait_for_app
    test_endpoints
    show_status
    
    print_success "DAST environment setup completed!"
    print_status "You can now run DAST scans against http://localhost:${PORT}"
    print_status "Use 'docker logs ${CONTAINER_NAME}' to view application logs"
    print_status "Use './scripts/cleanup-dast.sh' to clean up resources"
}

# Handle script arguments
case "${1:-setup}" in
    "setup")
        main
        ;;
    "cleanup")
        cleanup
        print_success "Cleanup completed."
        ;;
    "status")
        show_status
        ;;
    "test")
        test_endpoints
        ;;
    *)
        echo "Usage: $0 [setup|cleanup|status|test]"
        echo "  setup   - Setup DAST environment (default)"
        echo "  cleanup - Clean up resources"
        echo "  status  - Show current status"
        echo "  test    - Test API endpoints"
        exit 1
        ;;
esac
