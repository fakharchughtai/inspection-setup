#!/bin/bash

# Inspection Services Management Script
# This script manages the Docker containers for inspection-api and inspection-ui

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_message "$RED" "Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        print_message "$RED" "Error: Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
}

# Function to get the docker compose command
get_compose_cmd() {
    if docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# Start services
start_services() {
    print_message "$BLUE" "Starting Inspection services..."
    check_docker
    check_docker_compose
    
    local compose_cmd=$(get_compose_cmd)
    cd "$SCRIPT_DIR"
    
    print_message "$YELLOW" "Building and starting containers..."
    $compose_cmd -f "$COMPOSE_FILE" up -d --build
    
    print_message "$GREEN" "✓ Services started successfully!"
    print_message "$BLUE" "
Services are now running:
  - PostgreSQL Database: localhost:5432
  - Backend API: http://localhost:3000
  - Frontend UI: http://localhost:3001

Use './manage.sh logs' to view logs
Use './manage.sh status' to check service status
"
}

# Stop services
stop_services() {
    print_message "$BLUE" "Stopping Inspection services..."
    check_docker
    check_docker_compose
    
    local compose_cmd=$(get_compose_cmd)
    cd "$SCRIPT_DIR"
    
    $compose_cmd -f "$COMPOSE_FILE" down
    
    print_message "$GREEN" "✓ Services stopped successfully!"
}

# Restart services
restart_services() {
    print_message "$BLUE" "Restarting Inspection services..."
    stop_services
    sleep 2
    start_services
}

# Show service status
show_status() {
    print_message "$BLUE" "Inspection Services Status:"
    check_docker
    check_docker_compose
    
    local compose_cmd=$(get_compose_cmd)
    cd "$SCRIPT_DIR"
    
    $compose_cmd -f "$COMPOSE_FILE" ps
}

# Show service logs
show_logs() {
    check_docker
    check_docker_compose
    
    local compose_cmd=$(get_compose_cmd)
    cd "$SCRIPT_DIR"
    
    if [ -z "$1" ]; then
        print_message "$BLUE" "Showing logs for all services (Ctrl+C to exit)..."
        $compose_cmd -f "$COMPOSE_FILE" logs -f
    else
        print_message "$BLUE" "Showing logs for $1 (Ctrl+C to exit)..."
        $compose_cmd -f "$COMPOSE_FILE" logs -f "$1"
    fi
}

# Stop and remove all containers, networks, and volumes
cleanup() {
    print_message "$YELLOW" "⚠️  Warning: This will remove all containers, networks, and volumes!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        check_docker
        check_docker_compose
        
        local compose_cmd=$(get_compose_cmd)
        cd "$SCRIPT_DIR"
        
        print_message "$BLUE" "Cleaning up..."
        $compose_cmd -f "$COMPOSE_FILE" down -v --remove-orphans
        
        print_message "$GREEN" "✓ Cleanup completed!"
    else
        print_message "$YELLOW" "Cleanup cancelled."
    fi
}

# Rebuild services
rebuild_services() {
    print_message "$BLUE" "Rebuilding Inspection services..."
    check_docker
    check_docker_compose
    
    local compose_cmd=$(get_compose_cmd)
    cd "$SCRIPT_DIR"
    
    if [ -z "$1" ]; then
        print_message "$YELLOW" "Rebuilding all services..."
        $compose_cmd -f "$COMPOSE_FILE" build --no-cache
    else
        print_message "$YELLOW" "Rebuilding $1..."
        $compose_cmd -f "$COMPOSE_FILE" build --no-cache "$1"
    fi
    
    print_message "$GREEN" "✓ Rebuild completed!"
    print_message "$BLUE" "Use './manage.sh start' to start the services"
}

# Execute command in a service container
exec_command() {
    local service=$1
    shift
    local command="$@"
    
    check_docker
    check_docker_compose
    
    local compose_cmd=$(get_compose_cmd)
    cd "$SCRIPT_DIR"
    
    if [ -z "$service" ]; then
        print_message "$RED" "Error: Please specify a service name"
        print_message "$YELLOW" "Available services: postgres, api, ui"
        exit 1
    fi
    
    if [ -z "$command" ]; then
        print_message "$BLUE" "Opening shell in $service..."
        $compose_cmd -f "$COMPOSE_FILE" exec "$service" sh
    else
        print_message "$BLUE" "Executing command in $service: $command"
        $compose_cmd -f "$COMPOSE_FILE" exec "$service" $command
    fi
}

# Show help
show_help() {
    cat << EOF
Inspection Services Management Script

Usage: ./manage.sh [command] [options]

Commands:
  start               Start all services
  stop                Stop all services
  restart             Restart all services
  status              Show status of all services
  logs [service]      Show logs (optionally for a specific service)
  rebuild [service]   Rebuild services (optionally a specific service)
  cleanup             Stop and remove all containers, networks, and volumes
  exec <service> [cmd] Execute command in service container (opens shell if no command)
  help                Show this help message

Services:
  postgres            PostgreSQL Database
  api                 Backend API (NestJS)
  ui                  Frontend UI (Next.js)

Examples:
  ./manage.sh start
  ./manage.sh logs api
  ./manage.sh exec api npm run migration:run
  ./manage.sh rebuild api
  ./manage.sh stop

EOF
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    rebuild)
        rebuild_services "$2"
        ;;
    cleanup)
        cleanup
        ;;
    exec)
        shift
        exec_command "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_message "$RED" "Error: Unknown command '$1'"
        echo
        show_help
        exit 1
        ;;
esac

exit 0
