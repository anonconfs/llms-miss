#!/bin/bash

# 11byChatGPT - Owner Panel Update Script
# This script updates the owner panel application
# Created by ChatGPT - April 2025

# Exit on error
set -e

echo "===================================="
echo " 11byChatGPT Owner Panel Update    "
echo "===================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 
  exit 1
fi

# Check if app archive was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 owner_archive.zip"
    exit 1
fi

OWNER_ARCHIVE=$1
OWNER_DIR="/var/www/11bychatgpt/owner"
BACKUP_DIR="/var/www/11bychatgpt/data/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check if the archive exists
if [ ! -f "$OWNER_ARCHIVE" ]; then
    echo "Error: Archive file $OWNER_ARCHIVE not found!"
    exit 1
fi

echo "[1/5] Creating backup..."
# Create a backup of the current owner panel
tar -czf $BACKUP_DIR/owner_backup_$TIMESTAMP.tar.gz $OWNER_DIR

echo "[2/5] Stopping service..."
# Stop the owner panel service
systemctl stop 11bychatgpt-owner

echo "[3/5] Updating owner panel files..."
# Extract the archive to a temporary location
TMP_DIR=$(mktemp -d)
unzip -q $OWNER_ARCHIVE -d $TMP_DIR

# Remove old owner panel files but preserve the node_modules directory if it exists
if [ -d "$OWNER_DIR/node_modules" ]; then
    mv $OWNER_DIR/node_modules $TMP_DIR/node_modules_bak
fi

# Clear owner panel directory
rm -rf $OWNER_DIR/*

# Copy new files
cp -r $TMP_DIR/* $OWNER_DIR/

# Restore node_modules if it was backed up
if [ -d "$TMP_DIR/node_modules_bak" ]; then
    mv $TMP_DIR/node_modules_bak $OWNER_DIR/node_modules
fi

# Install dependencies
echo "[4/5] Installing dependencies..."
cd $OWNER_DIR
npm install --production

# Set proper permissions
chown -R www-data:www-data $OWNER_DIR
chmod -R 755 $OWNER_DIR

echo "[5/5] Starting service..."
# Start the owner panel service
systemctl start 11bychatgpt-owner

# Clean up temp directory
rm -rf $TMP_DIR

echo "===================================="
echo "   Owner Panel Update Complete!    "
echo "===================================="
echo ""
echo "The owner panel has been updated successfully!"
echo "A backup of the previous version was created at:"
echo "$BACKUP_DIR/owner_backup_$TIMESTAMP.tar.gz"
echo ""
echo "To check the owner panel status, run:"
echo "systemctl status 11bychatgpt-owner"
echo ""
echo "===================================="