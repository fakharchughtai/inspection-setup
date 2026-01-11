# 🛡️ ClamAV Scanner - Usage Guide

On-demand malware scanning using ClamAV in Docker. **Does not auto-start** with normal docker compose commands.

---

## ⚙️ ClamAV Management

### Start ClamAV (Manual)
```bash
cd /var/www/inspection-setup
docker compose --profile tools up -d clamav
```
**Note:** Scripts automatically start ClamAV, so you rarely need this.

### Stop ClamAV
```bash
cd /var/www/inspection-setup
docker compose stop clamav
```
**Note:** Scripts automatically stop ClamAV after scanning.

### Check ClamAV Status
```bash
# Check if ClamAV is running
docker ps | grep clamav

# View ClamAV logs
docker compose logs clamav

# Check virus database version
docker exec inspection-clamav sigtool --version-sig /var/lib/clamav/main.cvd
```

---

## 🚀 Quick Start

```bash
# Quick malware check (2-3 minutes)
cd /var/www/inspection-setup
./scripts/scan-quick.sh

# Full system scan (10-15 minutes)
./scripts/scan-all.sh full
```

---
---

### 4. **Image Scan** - Pre-deployment check
```bash
# Scan all inspection images
./scripts/scan-images.sh

# Scan specific image
./scripts/scan-images.sh inspection-setup-ui:latest
./scripts/scan-images.sh inspection-setup-api:latest
```
**Scans:**
- Docker images (before they run)
- All image layers
- Build-time malware

**Duration:** 5-10 minutes per image  
**Use when:** Before deployment, in CI/CD pipeline

---

## 📊 Scan Reports

All reports saved to: `/var/www/inspection-setup/scan-reports/`

```bash
# View latest quick scan
cat scan-reports/quick-scan-*.log | tail -50

# View latest full scan
cat scan-reports/scan-*.log | tail -100

# List all reports
ls -lth scan-reports/

# Check for infections
grep "FOUND" scan-reports/*.log
```

**Report naming:**
- `scan-YYYYMMDD-HHMMSS.log` - Full scans
- `quick-scan-YYYYMMDD-HHMMSS.log` - Quick scans
- `container-scan-YYYYMMDD-HHMMSS.log` - Container scans
- `image-scan-YYYYMMDD-HHMMSS.log` - Image scans

---

## ✅ Verification

### Confirm ClamAV is NOT auto-starting:
```bash
# Normal docker commands should NOT start ClamAV
cd /var/www/inspection-setup
docker compose up -d
docker compose ps

# Should only show: postgres, api, ui (NO clamav)
```

### Confirm ClamAV starts on-demand:
```bash
# Run a scan
./scripts/scan-quick.sh

# During scan, check containers
docker ps | grep clamav
# Should show: inspection-clamav running

# After scan completes
docker ps | grep clamav
# Should show: nothing (ClamAV stopped)
```

---

## 🎯 How It Works

```
1. You run script:
   $ ./scripts/scan-quick.sh

2. Script starts ClamAV:
   $ docker compose up -d clamav
   (Uses profile: tools - won't start with normal compose up)

3. Updates virus definitions:
   $ docker exec inspection-clamav freshclam

4. Performs scan:
   $ docker exec inspection-clamav clamscan -r /scan/...

5. Generates report:
   → /var/www/inspection-setup/scan-reports/

6. Stops ClamAV:
   $ docker compose stop clamav
   (Frees memory and CPU)
```

---

## 📦 What Gets Scanned

ClamAV mounts these directories (read-only):

| Directory | Mounted As | Contents |
|-----------|------------|----------|
| `/var/www` | `/scan/var/www` | All source code |
| `/tmp` | `/scan/tmp` | System temp files |
| `/var/tmp` | `/scan/var/tmp` | System temp files |
| `/home/ubuntu` | `/scan/home/ubuntu` | User home directory |
| `postgres_data` volume | `/scan/volumes/postgres_data` | Database files |
| `api_uploads` volume | `/scan/volumes/api_uploads` | Uploaded files |

---

## 🔐 Security Notes

1. ✅ **Read-only access** - ClamAV cannot modify files
2. ✅ **No auto-start** - Only runs when you explicitly call it
3. ✅ **Auto-stops** - Frees resources after scan
4. ✅ **Reports only** - Does not auto-delete infected files
5. ✅ **No network** - Cannot send data externally

---

## 🚨 If Malware Found

```bash
# 1. Review the report
cat scan-reports/quick-scan-*.log | grep "FOUND"

# 2. Stop affected container
docker compose stop ui  # or api

# 3. Remove malware manually
# Example: sudo rm -rf /var/tmp/.unix

# 4. Verify removal
./scripts/scan-quick.sh

# 5. Restart container
docker compose up -d ui
```

**Important:** Investigate the source! See `/home/ubuntu/melware_incident_report.md`

---

## 📅 Recommended Schedule

| Task | Frequency | Command |
|------|-----------|---------|
| Quick check | Daily | `./scripts/scan-quick.sh` |
| Full scan | Weekly | `./scripts/scan-all.sh full` |
| Image scan | Before deploy | `./scripts/scan-images.sh` |
| Container scan | On suspicion | `./scripts/scan-containers.sh` |

### Automate with Cron:
```bash
# Edit crontab
crontab -e

# Add daily 2 AM scan
0 2 * * * cd /var/www/inspection-setup && ./scripts/scan-quick.sh >> /var/log/clamav-auto.log 2>&1

# Add weekly Sunday 3 AM full scan
0 3 * * 0 cd /var/www/inspection-setup && ./scripts/scan-all.sh full >> /var/log/clamav-auto.log 2>&1
```

---

## 🛠️ Troubleshooting

### ClamAV won't start
```bash
# Check for existing container
docker ps -a | grep clamav

# Remove old container
docker rm -f inspection-clamav

# Try scan again
./scripts/scan-quick.sh
```

### Virus definitions outdated
```bash
# Manual update
docker compose up -d clamav
docker exec inspection-clamav freshclam
docker compose stop clamav
```

### Scan takes too long
```bash
# Use quick mode instead of full
./scripts/scan-all.sh quick

# Or just scan critical areas
./scripts/scan-quick.sh
```

### Disk space full
```bash
# Check virus database size
docker volume inspect inspection-setup_clamav_db

# Clean old reports
rm -f scan-reports/*.log

# Keep only last 7 days
find scan-reports/ -name "*.log" -mtime +7 -delete
```

---

## 💡 Pro Tips

1. **Run scans during low traffic** (night/early morning)
2. **Check reports regularly** - Don't ignore them
3. **Scan before deployments** - Catch malware early
4. **Keep definitions updated** - Auto-updates on each scan
5. **Monitor disk space** - Virus DB is ~200MB

---

## 🔗 Related Files

- **Docker Compose:** `../docker-compose.yml` - ClamAV service definition
- **Malware Report:** `/home/ubuntu/melware_incident_report.md` - Previous incident details
- **Scan Reports:** `../scan-reports/` - All scan results

---

## 📞 Examples

### Example 1: Daily morning check
```bash
#!/bin/bash
# /var/www/inspection-setup/scripts/daily-check.sh
cd /var/www/inspection-setup
./scripts/scan-quick.sh

if [ $? -ne 0 ]; then
  echo "⚠️  ALERT: Malware detected!" | mail -s "Malware Alert" admin@example.com
fi
```

### Example 2: Pre-deployment scan
```bash
#!/bin/bash
# Before deploying new images
cd /var/www/inspection-setup

echo "Scanning new images before deployment..."
./scripts/scan-images.sh inspection-setup-ui:latest
./scripts/scan-images.sh inspection-setup-api:latest

if [ $? -eq 0 ]; then
  echo "✅ Images clean, proceeding with deployment"
  docker compose up -d
else
  echo "❌ Malware found, deployment aborted"
  exit 1
fi
```

### Example 3: Check specific directory
```bash
# Custom scan of specific directory
docker compose up -d clamav
sleep 5
docker exec inspection-clamav clamscan -r /scan/var/www/inspection-api/uploads
docker compose stop clamav
```

---

## 🆘 Need Help?

1. **Check the logs:**
   ```bash
   docker compose logs clamav
   ```

2. **View scan reports:**
   ```bash
   ls -lth scan-reports/
   ```

3. **Manual ClamAV commands:**
   ```bash
   # Start ClamAV
   docker compose up -d clamav
   
   # Check status
   docker exec inspection-clamav clamd --version
   
   # Update definitions
   docker exec inspection-clamav freshclam
   
   # Manual scan
   docker exec inspection-clamav clamscan -r /scan/tmp
   
   # Stop ClamAV
   docker compose stop clamav
   ```

4. **Review incident report:**
   ```bash
   less /home/ubuntu/melware_incident_report.md
   ```

---

**Last Updated:** January 11, 2026  
**Version:** 1.0
