#!/bin/bash

# Quick Status and Logs Script
# This script shows the status and recent logs for all services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Inspection Services Status ===${NC}"
echo ""
"$SCRIPT_DIR/manage.sh" status
echo ""
echo -e "${YELLOW}Recent logs (last 50 lines):${NC}"
echo -e "${BLUE}Use Ctrl+C to stop following logs${NC}"
echo ""
sleep 2
"$SCRIPT_DIR/manage.sh" logs
