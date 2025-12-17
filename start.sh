#!/bin/bash

# Quick Start Script for Inspection Services
# This script provides shortcuts for common operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Inspection Services...${NC}"
"$SCRIPT_DIR/manage.sh" start
