#!/bin/bash
# Quick scan for known malware signatures
# Scans only critical locations where malware was previously found

set -e

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_DIR="/var/www/inspection-setup/scan-reports"
REPORT_FILE="$REPORT_DIR/quick-scan-$TIMESTAMP.log"

mkdir -p "$REPORT_DIR"

echo "========================================" | tee "$REPORT_FILE"
echo "Quick Malware Scan - $TIMESTAMP" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Start ClamAV
echo "[$(date '+%H:%M:%S')] Starting ClamAV..." | tee -a "$REPORT_FILE"
docker compose -f /var/www/inspection-setup/docker-compose.yml up -d clamav
sleep 5

echo "[$(date +%H:%M:%S)] Waiting for virus definitions..." | tee -a "$REPORT_FILE"
sleep 15

# Scan critical locations only
echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Scanning /tmp and /var/tmp..." | tee -a "$REPORT_FILE"
docker exec inspection-clamav clamscan -r /scan/tmp /scan/var/tmp 2>&1 | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Checking for known malware files..." | tee -a "$REPORT_FILE"

# Check for specific malware signatures
MALWARE_FILES=(
  "/scan/var/tmp/.unix/javae"
  "/scan/var/tmp/.unix/config.json"
  "/scan/tmp/.unix/javae"
  "/scan/var/tmp/.bin"
)

for file in "${MALWARE_FILES[@]}"; do
  if docker exec inspection-clamav test -e "$file" 2>/dev/null; then
    echo "⚠️  FOUND: $file" | tee -a "$REPORT_FILE"
    docker exec inspection-clamav clamscan "$file" 2>&1 | tee -a "$REPORT_FILE"
  fi
done

# Scan running containers for malware processes
echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Checking containers for malware processes..." | tee -a "$REPORT_FILE"

for container in inspection-ui inspection-api; do
  if docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "$container"; then
    echo "Checking $container..." | tee -a "$REPORT_FILE"
    docker exec "$container" ps aux 2>/dev/null | grep -E "javae|xmrig|kdevtmpfsi" | grep -v grep || echo "  ✅ Clean" | tee -a "$REPORT_FILE"
  fi
done

echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "SCAN SUMMARY" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

INFECTED=$(grep -c "FOUND" "$REPORT_FILE" || echo "0")

if [ "$INFECTED" -gt 0 ]; then
  echo "⚠️  WARNING: $INFECTED infected file(s) found!" | tee -a "$REPORT_FILE"
  echo "" | tee -a "$REPORT_FILE"
  grep "FOUND" "$REPORT_FILE" | tee -a "$REPORT_FILE"
else
  echo "✅ No infected files found" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "[$(date '+%H:%M:%S')] Quick scan completed" | tee -a "$REPORT_FILE"
echo "Report: $REPORT_FILE" | tee -a "$REPORT_FILE"

# Stop ClamAV
docker compose -f /var/www/inspection-setup/docker-compose.yml stop clamav

if [ "$INFECTED" -gt 0 ]; then
  exit 1
fi
