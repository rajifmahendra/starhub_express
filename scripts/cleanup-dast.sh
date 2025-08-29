#!/bin/bash

# StarHub Express DAST Cleanup Script
# Script untuk membersihkan environment DAST testing

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
NETWORK_NAME="dast-network"
CHECKMARX_CONTAINER="checkmarx-dast-runner"

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

echo "🧹 Cleaning up DAST environment..."
echo "=================================="

# Stop and remove application container
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping and removing container: ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
    print_success "Container ${CONTAINER_NAME} removed."
else
    print_warning "Container ${CONTAINER_NAME} not found."
fi

# Stop and remove Checkmarx DAST container
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CHECKMARX_CONTAINER}$"; then
    print_status "Stopping and removing container: ${CHECKMARX_CONTAINER}"
    docker stop ${CHECKMARX_CONTAINER} >/dev/null 2>&1 || true
    docker rm ${CHECKMARX_CONTAINER} >/dev/null 2>&1 || true
    print_success "Container ${CHECKMARX_CONTAINER} removed."
else
    print_warning "Container ${CHECKMARX_CONTAINER} not found."
fi

# Remove Docker network
if docker network ls --format 'table {{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
    print_status "Removing network: ${NETWORK_NAME}"
    docker network rm ${NETWORK_NAME} >/dev/null 2>&1 || true
    print_success "Network ${NETWORK_NAME} removed."
else
    print_warning "Network ${NETWORK_NAME} not found."
fi

# Optional: Remove Docker image
if [ "${1}" = "--remove-image" ]; then
    if docker images --format 'table {{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}:"; then
        print_status "Removing Docker image: ${IMAGE_NAME}"
        docker rmi ${IMAGE_NAME}:latest >/dev/null 2>&1 || true
        print_success "Docker image removed."
    else
        print_warning "Docker image ${IMAGE_NAME} not found."
    fi
fi

# Optional: Clean output directory
if [ "${1}" = "--clean-output" ] || [ "${2}" = "--clean-output" ]; then
    if [ -d "output" ]; then
        print_status "Cleaning output directory"
        rm -rf output
        print_success "Output directory cleaned."
    else
        print_warning "Output directory not found."
    fi
fi

# Show remaining Docker resources
print_status "Remaining Docker resources:"
echo ""
echo "🐳 Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10

echo ""
echo "🌐 Networks:"
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | head -10

echo ""
echo "💾 Images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(starhub|checkmarx)" || echo "No StarHub or Checkmarx images found"

echo ""
print_success "DAST environment cleanup completed!"
print_status "Use '--remove-image' to also remove the Docker image"
print_status "Use '--clean-output' to also clean the output directory"
