#!/bin/bash
# Scan Docker images for malware
# Usage: ./scan-images.sh [image-name]

set -e

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_DIR="/var/www/inspection-setup/scan-reports"
REPORT_FILE="$REPORT_DIR/image-scan-$TIMESTAMP.log"

mkdir -p "$REPORT_DIR"

echo "========================================" | tee "$REPORT_FILE"
echo "Docker Image Scan - $TIMESTAMP" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Get images to scan
if [ -n "$1" ]; then
  IMAGES="$1"
  echo "Scanning specific image: $1" | tee -a "$REPORT_FILE"
else
  IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "none" | grep -E "inspection-|clamav")
  echo "Scanning all inspection images:" | tee -a "$REPORT_FILE"
  echo "$IMAGES" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

# Start ClamAV
echo "[$(date '+%H:%M:%S')] Starting ClamAV..." | tee -a "$REPORT_FILE"
docker compose -f /var/www/inspection-setup/docker-compose.yml up -d clamav
sleep 5

echo "[$(date +%H:%M:%S)] Waiting for virus definitions..." | tee -a "$REPORT_FILE"
sleep 15
# Update definitions

# Scan each image
while IFS= read -r IMAGE; do
  [ -z "$IMAGE" ] && continue
  
  IMAGE_NAME=$(echo "$IMAGE" | tr ':/' '-')
  
  echo "" | tee -a "$REPORT_FILE"
  echo "========================================" | tee -a "$REPORT_FILE"
  echo "Scanning image: $IMAGE" | tee -a "$REPORT_FILE"
  echo "========================================" | tee -a "$REPORT_FILE"
  
  # Save image as tar
  echo "[$(date '+%H:%M:%S')] Exporting image..." | tee -a "$REPORT_FILE"
  docker save "$IMAGE" -o "/tmp/image-$IMAGE_NAME.tar"
  
  # Copy to ClamAV and scan
  docker cp "/tmp/image-$IMAGE_NAME.tar" inspection-clamav:/tmp/
  
  echo "[$(date '+%H:%M:%S')] Scanning..." | tee -a "$REPORT_FILE"
  docker exec inspection-clamav sh -c "
    mkdir -p /tmp/scan-$IMAGE_NAME && 
    cd /tmp/scan-$IMAGE_NAME && 
    tar -xf /tmp/image-$IMAGE_NAME.tar && 
    clamscan -r --infected . 2>&1
  " | tee -a "$REPORT_FILE"
  
  # Cleanup
  docker exec inspection-clamav rm -rf "/tmp/image-$IMAGE_NAME.tar" "/tmp/scan-$IMAGE_NAME"
  rm -f "/tmp/image-$IMAGE_NAME.tar"
  
done <<< "$IMAGES"

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
