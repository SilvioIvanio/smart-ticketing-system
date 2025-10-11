#!/bin/bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Smart Ticketing System - Build All Services (Linux/Mac)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track build results
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0
TOTAL_SERVICES=6

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Building All Microservices${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Array of services to build
SERVICES=(
    "passenger-service/passenger_service"
    "ticketing-service/ticketing_service"
    "payment-service/payment_service"
    "admin-service/admin_service"
    "transport-service/transport_service"
    "notification-service/notification_service"
)

# Function to build a service
build_service() {
    local service_path=$1
    local service_name=$(basename $(dirname $service_path))
    
    echo -e "${YELLOW}▶ Building: ${service_name}${NC}"
    echo "  Path: ${service_path}"
    
    if [ ! -d "$service_path" ]; then
        echo -e "${RED}  ✗ ERROR: Directory not found${NC}"
        FAILED_BUILDS=$((FAILED_BUILDS + 1))
        return 1
    fi
    
    cd "$service_path"
    
    if bal build > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ SUCCESS: ${service_name} built successfully${NC}"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
    else
        echo -e "${RED}  ✗ FAILED: ${service_name} build failed${NC}"
        echo -e "${RED}     Run 'bal build' manually in ${service_path} for details${NC}"
        FAILED_BUILDS=$((FAILED_BUILDS + 1))
    fi
    
    cd - > /dev/null
    echo ""
}

# Save current directory
ORIGINAL_DIR=$(pwd)

# Build each service
for service in "${SERVICES[@]}"; do
    build_service "$service"
done

# Return to original directory
cd "$ORIGINAL_DIR"

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Build Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Total Services: ${TOTAL_SERVICES}"
echo -e "  ${GREEN}Successful: ${SUCCESSFUL_BUILDS}${NC}"
echo -e "  ${RED}Failed: ${FAILED_BUILDS}${NC}"
echo ""

if [ $FAILED_BUILDS -eq 0 ]; then
    echo -e "${GREEN}✓ All services built successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Go to project root: cd .."
    echo "  2. Start services: docker-compose up -d"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some services failed to build${NC}"
    echo -e "${YELLOW}Fix the errors and run this script again${NC}"
    echo ""
    exit 1
fi