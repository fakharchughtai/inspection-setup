# Inspection Services - Quick Reference

## 🚀 Quick Commands

```bash
# Start services
./start.sh

# Stop services
./stop.sh

# Restart services
./restart.sh

# Check status & view logs
./status.sh
```

## 📊 Service Management

```bash
# View status
./manage.sh status

# View logs for all services
./manage.sh logs

# View logs for specific service
./manage.sh logs api
./manage.sh logs ui
./manage.sh logs postgres

# Rebuild services
./manage.sh rebuild          # all services
./manage.sh rebuild api      # just API
./manage.sh rebuild ui       # just UI
```

## 🔧 Advanced Operations

```bash
# Execute commands in containers
./manage.sh exec api         # open shell in API
./manage.sh exec ui          # open shell in UI

# Run migrations
./manage.sh exec api npm run migration:run

# Seed database
./manage.sh exec api npm run seed

# Access PostgreSQL
./manage.sh exec postgres psql -U postgres -d inspection_db

# Complete cleanup (removes all data)
./manage.sh cleanup
```

## 🌐 Access URLs

- Frontend UI: http://localhost:3001
- Backend API: http://localhost:3000
- API Health: http://localhost:3000/health
- PostgreSQL: localhost:5432

## 🔑 Default Credentials

**Database:**
- Host: localhost
- Port: 5432
- Database: inspection_db
- Username: postgres
- Password: postgres123

## 📦 Services

| Service | Container Name | Port | Description |
|---------|----------------|------|-------------|
| postgres | inspection-postgres | 5432 | PostgreSQL Database |
| api | inspection-api | 3000 | Backend API (NestJS) |
| ui | inspection-ui | 3001 | Frontend UI (Next.js) |

## 🆘 Troubleshooting

```bash
# Check if Docker is running
docker info

# Check for port conflicts
lsof -i :3000
lsof -i :3001
lsof -i :5432

# View detailed logs
./manage.sh logs api

# Restart specific service
docker restart inspection-api
docker restart inspection-ui

# Clean rebuild
./manage.sh cleanup
./manage.sh rebuild
./manage.sh start
```

## 📝 Common Tasks

### Update code and restart
```bash
# After making code changes
./manage.sh rebuild api      # if API changed
./manage.sh rebuild ui       # if UI changed
./manage.sh restart
```

### Check API health
```bash
curl http://localhost:3000/health
```

### Database operations
```bash
# Generate migration
./manage.sh exec api npm run migration:generate

# Run migration
./manage.sh exec api npm run migration:run

# Revert migration
./manage.sh exec api npm run migration:revert
```

### View running containers
```bash
docker ps
# or
./manage.sh status
```

### Access container logs directly
```bash
docker logs inspection-api -f
docker logs inspection-ui -f
docker logs inspection-postgres -f
```

## ⚙️ Configuration

Edit `.env` file for custom configuration:
```bash
cp .env.example .env
nano .env
```

Then restart services:
```bash
./restart.sh
```

## 🔄 First Time Setup

```bash
# 1. Make scripts executable
chmod +x *.sh

# 2. (Optional) Copy and configure environment
cp .env.example .env
nano .env

# 3. Start services
./start.sh

# 4. Wait for services to be healthy (check status)
./status.sh

# 5. Access the application
open http://localhost:3001
```
