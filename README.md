# Inspection Services Docker Setup

This directory contains Docker Compose configuration and management scripts to run both the inspection-api (NestJS backend) and inspection-ui (Next.js frontend) services together.

## 📋 Prerequisites

- Docker Engine 20.10+ installed
- Docker Compose v2.0+ installed
- At least 4GB RAM available for Docker
- Ports 3000, 3001, 5432, and 6379 available on your host machine

## 🚀 Quick Start

### 1. Start All Services

```bash
# Make scripts executable (first time only)
chmod +x *.sh

# Start all services (database, cache, API, and UI)
./start.sh

# Or use the full management script
./manage.sh start
```

### 2. Access the Application

Once all services are running:

- **Frontend UI**: http://localhost:3001
- **Backend API**: http://localhost:3000
- **API Health Check**: http://localhost:3000/health
- **PostgreSQL**: localhost:5432

### 3. Stop Services

```bash
./stop.sh

# Or use the management script
./manage.sh stop
```

## 🛠️ Management Scripts

### Main Management Script

The `manage.sh` script provides comprehensive service management:

```bash
./manage.sh [command] [options]
```

#### Available Commands

| Command | Description |
|---------|-------------|
| `start` | Start all services |
| `stop` | Stop all services |
| `restart` | Restart all services |
| `status` | Show status of all services |
| `logs [service]` | Show logs (optionally for a specific service) |
| `rebuild [service]` | Rebuild services (optionally a specific service) |
| `cleanup` | Stop and remove all containers, networks, and volumes |
| `exec <service> [cmd]` | Execute command in service container |
| `help` | Show help message |

#### Service Names

- `postgres` - PostgreSQL Database
- `api` - Backend API (NestJS)
- `ui` - Frontend UI (Next.js)

### Quick Scripts

For convenience, quick scripts are provided:

- `./start.sh` - Start all services
- `./stop.sh` - Stop all services
- `./restart.sh` - Restart all services

## 📖 Usage Examples

### View Logs

```bash
# View all service logs
./manage.sh logs

# View logs for specific service
./manage.sh logs api
./manage.sh logs ui
./manage.sh logs postgres
```

### Check Service Status

```bash
./manage.sh status
```

### Rebuild Services

```bash
# Rebuild all services
./manage.sh rebuild

# Rebuild specific service
./manage.sh rebuild api
./manage.sh rebuild ui
```

### Execute Commands in Containers

```bash
# Open shell in API container
./manage.sh exec api

# Run database migrations
./manage.sh exec api npm run migration:run

# Open shell in UI container
./manage.sh exec ui

# Access PostgreSQL
./manage.sh exec postgres psql -U postgres -d inspection_db
```

### Complete Cleanup

```bash
# Remove all containers, networks, and volumes
./manage.sh cleanup
```

## 🏗️ Architecture

The Docker Compose setup includes:

1. **PostgreSQL Database** (postgres:16-alpine)
   - Port: 5432
   - Database: inspection_db
   - User: postgres
   - Password: postgres123

2. **Backend API** (NestJS)
   - Port: 3000
   - Built from `../inspection-api`
   - Depends on: PostgreSQL

3. **Frontend UI** (Next.js)
   - Port: 3001
   - Built from `../inspection-ui`
   - Depends on: Backend API

## 🔧 Configuration

### Environment Variables

The default configuration is set in `docker-compose.yml`. To customize:

1. Create a `.env` file in this directory:

```bash
cp .env.example .env
```

2. Edit the `.env` file with your configuration:

```env
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRATION=7d

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-password
SMTP_FROM=noreply@inspection.com

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH=./uploads

# CORS
CORS_ORIGIN=http://localhost:3001

# API URL for Frontend
NEXT_PUBLIC_API_URL=http://localhost:3000
```

### Database Configuration

Default database credentials:
- Host: postgres (container name) / localhost (from host)
- Port: 5432
- Database: inspection_db
- Username: postgres
- Password: postgres123

To change these, edit the `postgres` service in `docker-compose.yml`.

## 📦 Volumes

Persistent data is stored in Docker volumes:

- `postgres_data` - PostgreSQL database data
- `api_uploads` - Uploaded files from API

These volumes persist even when containers are stopped or removed.

## 🔍 Troubleshooting

### Services won't start

1. Check if Docker is running:
   ```bash
   docker info
   ```

2. Check for port conflicts:
   ```bash
   lsof -i :3000
   lsof -i :3001
   lsof -i :5432
   ```

3. View service logs:
   ```bash
   ./manage.sh logs
   ```

### Build failures

1. Clean and rebuild:
   ```bash
   ./manage.sh cleanup
   ./manage.sh rebuild
   ./manage.sh start
   ```

2. Check Docker disk space:
   ```bash
   docker system df
   docker system prune
   ```

### Database connection issues

1. Ensure PostgreSQL is healthy:
   ```bash
   ./manage.sh status
   ```

2. Check database logs:
   ```bash
   ./manage.sh logs postgres
   ```

3. Connect to database:
   ```bash
   ./manage.sh exec postgres psql -U postgres -d inspection_db
   ```

### UI not connecting to API

1. Check API health:
   ```bash
   curl http://localhost:3000/health
   ```

2. Verify environment variables in UI:
   ```bash
   ./manage.sh exec ui env | grep NEXT_PUBLIC
   ```

## 🔄 Development Workflow

### Making Code Changes

1. Code changes in `../inspection-api` or `../inspection-ui` require rebuilding:
   ```bash
   ./manage.sh rebuild api  # for API changes
   ./manage.sh rebuild ui   # for UI changes
   ./manage.sh start
   ```

### Running Migrations

```bash
# Generate migration
./manage.sh exec api npm run migration:generate

# Run migrations
./manage.sh exec api npm run migration:run

# Revert migration
./manage.sh exec api npm run migration:revert
```

### Database Seeding

```bash
# Run seed data
./manage.sh exec api npm run seed
```

## 🚨 Production Considerations

This setup is primarily for **development and testing**. For production:

1. **Change default passwords** in `docker-compose.yml`
2. **Set strong JWT_SECRET** via environment variables
3. **Configure proper CORS** settings
4. **Use external database** instead of containerized PostgreSQL
5. **Set up SSL/TLS** for secure connections
6. **Configure proper logging** and monitoring
7. **Use environment-specific configurations**
8. **Set up backup strategies** for data volumes

## 📝 Notes

- First startup may take several minutes to build images
- Health checks ensure services start in correct order
- Logs are available via `./manage.sh logs`
- Data persists in Docker volumes across container restarts
- Use `./manage.sh cleanup` to remove all data and start fresh

## 🆘 Support

For issues or questions:
1. Check service logs: `./manage.sh logs`
2. Verify service status: `./manage.sh status`
3. Review the Docker Compose file: `docker-compose.yml`
4. Check individual service documentation in `../inspection-api` and `../inspection-ui`
