#!/bin/bash
# Scan running Docker containers from inside
# Usage: ./scan-containers.sh

set -e

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_DIR="/var/www/inspection-setup/scan-reports"
REPORT_FILE="$REPORT_DIR/container-scan-$TIMESTAMP.log"

mkdir -p "$REPORT_DIR"

echo "========================================" | tee "$REPORT_FILE"
echo "Docker Container Scan - $TIMESTAMP" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Get list of running containers
CONTAINERS=$(docker ps --format "{{.ID}} {{.Names}}")

echo "Running containers:" | tee -a "$REPORT_FILE"
echo "$CONTAINERS" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Start ClamAV
echo "[$(date '+%H:%M:%S')] Starting ClamAV..." | tee -a "$REPORT_FILE"
docker compose -f /var/www/inspection-setup/docker-compose.yml up -d clamav
sleep 5

echo "[$(date +%H:%M:%S)] Waiting for virus definitions..." | tee -a "$REPORT_FILE"
sleep 15
# Update virus definitions

# Scan each running container
while IFS= read -r line; do
  CONTAINER_ID=$(echo "$line" | awk '{print $1}')
  CONTAINER_NAME=$(echo "$line" | awk '{print $2}')
  
  echo "" | tee -a "$REPORT_FILE"
  echo "========================================" | tee -a "$REPORT_FILE"
  echo "Scanning container: $CONTAINER_NAME ($CONTAINER_ID)" | tee -a "$REPORT_FILE"
  echo "========================================" | tee -a "$REPORT_FILE"
  
  # Export container filesystem to temp location
  echo "[$(date '+%H:%M:%S')] Exporting container filesystem..." | tee -a "$REPORT_FILE"
  docker export "$CONTAINER_ID" -o "/tmp/container-$CONTAINER_NAME.tar"
  
  # Copy to ClamAV container and scan
  docker cp "/tmp/container-$CONTAINER_NAME.tar" inspection-clamav:/tmp/
  
  echo "[$(date '+%H:%M:%S')] Scanning..." | tee -a "$REPORT_FILE"
  docker exec inspection-clamav sh -c "
    mkdir -p /tmp/scan-$CONTAINER_NAME && 
    cd /tmp/scan-$CONTAINER_NAME && 
    tar -xf /tmp/container-$CONTAINER_NAME.tar && 
    clamscan -r --infected . 2>&1
  " | tee -a "$REPORT_FILE"
  
  # Cleanup
  docker exec inspection-clamav rm -rf "/tmp/container-$CONTAINER_NAME.tar" "/tmp/scan-$CONTAINER_NAME"
  rm -f "/tmp/container-$CONTAINER_NAME.tar"
  
done <<< "$CONTAINERS"

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
echo "[$(date '+%H:%M:%S')] Scan completed" | tee -a "$REPORT_FILE"
echo "Report: $REPORT_FILE" | tee -a "$REPORT_FILE"

# Stop ClamAV
docker compose -f /var/www/inspection-setup/docker-compose.yml stop clamav

if [ "$INFECTED" -gt 0 ]; then
  exit 1
fi
