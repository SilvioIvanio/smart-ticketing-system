#!/bin/bash

# ==============================================================================
# Smart Public Transport Ticketing System - Build All Services
# ==============================================================================
# This script builds all 6 microservices
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build counters
TOTAL_SERVICES=6
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Smart Ticketing System - Building All Microservices${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

build_service() {
    local service_name=$1
    local service_path=$2
    
    echo -e "${BLUE}▶ Building $service_name...${NC}"
    
    if [ ! -d "$service_path" ]; then
        echo -e "${RED}✗ ERROR: Directory not found: $service_path${NC}"
        ((FAILED_BUILDS++))
        return 1
    fi
    
    cd "$service_path" || exit
    
    if bal build > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $service_name built successfully${NC}"
        ((SUCCESSFUL_BUILDS++))
        cd - > /dev/null || exit
        return 0
    else
        echo -e "${RED}✗ $service_name build failed${NC}"
        echo -e "${YELLOW}  Running build with output for debugging...${NC}"
        bal build
        ((FAILED_BUILDS++))
        cd - > /dev/null || exit
        return 1
    fi
}

# Build all services
build_service "Passenger Service" "services/passenger-service/passenger_service"
build_service "Ticketing Service" "services/ticketing-service/ticketing_service"
build_service "Payment Service" "services/payment-service/payment_service"
build_service "Admin Service" "services/admin-service/admin_service"
build_service "Transport Service" "services/transport-service/transport_service"
build_service "Notification Service" "services/notification-service/notification_service"

# Build summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Build Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Total Services:      ${TOTAL_SERVICES}"
echo -e "${GREEN}Successful Builds:   ${SUCCESSFUL_BUILDS}${NC}"
echo -e "${RED}Failed Builds:       ${FAILED_BUILDS}${NC}"
echo ""

if [ $FAILED_BUILDS -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ All services built successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Start infrastructure: ${YELLOW}docker-compose up -d${NC}"
    echo -e "  2. Run all services: ${YELLOW}docker-compose up${NC}"
    echo -e "  3. Or run services individually with: ${YELLOW}bal run${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✗ Some services failed to build${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Please check the error messages above and fix the issues.${NC}"
    echo ""
    exit 1
fi