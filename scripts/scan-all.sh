#!/bin/bash
# Complete security scan using ClamAV in Docker
# Usage: ./scan-all.sh [quick|full]

set -e

SCAN_TYPE="${1:-quick}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_DIR="/var/www/inspection-setup/scan-reports"
REPORT_FILE="$REPORT_DIR/scan-$TIMESTAMP.log"

mkdir -p "$REPORT_DIR"

echo "========================================" | tee -a "$REPORT_FILE"
echo "ClamAV Security Scan - $TIMESTAMP" | tee -a "$REPORT_FILE"
echo "Scan Type: $SCAN_TYPE" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Start ClamAV container
echo "[$(date '+%H:%M:%S')] Starting ClamAV container..." | tee -a "$REPORT_FILE"
docker compose -f /var/www/inspection-setup/docker-compose.yml up -d clamav

# Wait for ClamAV to initialize and update definitions
# Wait for virus definitions to be ready (freshclam runs as daemon)
echo "[$(date +%H:%M:%S)] Waiting for virus definitions to load..." | tee -a "$REPORT_FILE"
sleep 10
echo "[$(date +%H:%M:%S)] Waiting for virus definitions..." | tee -a "$REPORT_FILE"
sleep 15

echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "SCANNING SOURCE CODE" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Scan source code directories
echo "[$(date '+%H:%M:%S')] Scanning /var/www/inspection-api..." | tee -a "$REPORT_FILE"
docker exec inspection-clamav clamscan -r \
  --exclude-dir="node_modules" \
  --exclude-dir=".git" \
  --infected \
  /scan/var/www/inspection-api 2>&1 | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Scanning /var/www/inspection-ui..." | tee -a "$REPORT_FILE"
docker exec inspection-clamav clamscan -r \
  --exclude-dir="node_modules" \
  --exclude-dir=".git" \
  --exclude-dir=".next" \
  --infected \
  /scan/var/www/inspection-ui 2>&1 | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "SCANNING SYSTEM DIRECTORIES" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Scan temp directories (where malware was found)
echo "[$(date '+%H:%M:%S')] Scanning /tmp..." | tee -a "$REPORT_FILE"
docker exec inspection-clamav clamscan -r /scan/tmp 2>&1 | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Scanning /var/tmp..." | tee -a "$REPORT_FILE"
docker exec inspection-clamav clamscan -r /scan/var/tmp 2>&1 | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "SCANNING DOCKER VOLUMES" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

echo "[$(date '+%H:%M:%S')] Scanning Docker volumes..." | tee -a "$REPORT_FILE"
docker exec inspection-clamav clamscan -r /scan/volumes 2>&1 | tee -a "$REPORT_FILE"

if [ "$SCAN_TYPE" = "full" ]; then
  echo "" | tee -a "$REPORT_FILE"
  echo "========================================" | tee -a "$REPORT_FILE"
  echo "SCANNING HOME DIRECTORY" | tee -a "$REPORT_FILE"
  echo "========================================" | tee -a "$REPORT_FILE"
  
  echo "[$(date '+%H:%M:%S')] Scanning /home/ubuntu..." | tee -a "$REPORT_FILE"
  docker exec inspection-clamav clamscan -r \
    --exclude-dir=".npm" \
    --exclude-dir=".cache" \
    /scan/home/ubuntu 2>&1 | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "SCAN SUMMARY" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Extract infected files count
INFECTED=$(grep -c "FOUND" "$REPORT_FILE" || echo "0")

if [ "$INFECTED" -gt 0 ]; then
  echo "⚠️  WARNING: $INFECTED infected file(s) found!" | tee -a "$REPORT_FILE"
  echo "" | tee -a "$REPORT_FILE"
  echo "Infected files:" | tee -a "$REPORT_FILE"
  grep "FOUND" "$REPORT_FILE" | tee -a "$REPORT_FILE"
else
  echo "✅ No infected files found" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Scan completed" | tee -a "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"

# Stop ClamAV container to free resources
echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Stopping ClamAV container..." | tee -a "$REPORT_FILE"
docker compose -f /var/www/inspection-setup/docker-compose.yml stop clamav

echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

# Exit with error code if infected files found
if [ "$INFECTED" -gt 0 ]; then
  exit 1
else
  exit 0
fi
