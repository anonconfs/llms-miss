#!/bin/bash

# 11byChatGPT - App Update Script
# This script updates the main application while preserving user data
# Created by ChatGPT - April 2025

# Exit on error
set -e

echo "===================================="
echo "   11byChatGPT App Update Script   "
echo "===================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 
  exit 1
fi

# Check if app archive was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 app_archive.zip"
    exit 1
fi

APP_ARCHIVE=$1
APP_DIR="/var/www/11bychatgpt/app"
BACKUP_DIR="/var/www/11bychatgpt/data/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check if the archive exists
if [ ! -f "$APP_ARCHIVE" ]; then
    echo "Error: Archive file $APP_ARCHIVE not found!"
    exit 1
fi

echo "[1/5] Creating backup..."
# Create a backup of the current app
tar -czf $BACKUP_DIR/app_backup_$TIMESTAMP.tar.gz $APP_DIR

echo "[2/5] Stopping service..."
# Stop the application service
systemctl stop 11bychatgpt

echo "[3/5] Updating application files..."
# Extract the archive to a temporary location
TMP_DIR=$(mktemp -d)
unzip -q $APP_ARCHIVE -d $TMP_DIR

# Remove old app files but preserve the node_modules directory if it exists
if [ -d "$APP_DIR/node_modules" ]; then
    mv $APP_DIR/node_modules $TMP_DIR/node_modules_bak
fi

# Clear application directory but preserve data
rm -rf $APP_DIR/*

# Copy new files
cp -r $TMP_DIR/* $APP_DIR/

# Restore node_modules if it was backed up
if [ -d "$TMP_DIR/node_modules_bak" ]; then
    mv $TMP_DIR/node_modules_bak $APP_DIR/node_modules
fi

# Install dependencies
echo "[4/5] Installing dependencies..."
cd $APP_DIR
npm install --production

# Set proper permissions
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

echo "[5/5] Starting service..."
# Start the application service
systemctl start 11bychatgpt

# Clean up temp directory
rm -rf $TMP_DIR

echo "===================================="
echo "   Application Update Complete!    "
echo "===================================="
echo ""
echo "The application has been updated successfully!"
echo "A backup of the previous version was created at:"
echo "$BACKUP_DIR/app_backup_$TIMESTAMP.tar.gz"
echo ""
echo "To check the application status, run:"
echo "systemctl status 11bychatgpt"
echo ""
echo "===================================="