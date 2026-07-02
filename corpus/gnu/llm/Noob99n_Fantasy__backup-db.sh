#!/bin/bash

# 11byChatGPT - Database and Uploads Backup Script
# This script creates backups of the database and user uploads
# Created by ChatGPT - April 2025

# Set variables
BACKUP_DIR="/var/www/11bychatgpt/data/backups"
UPLOADS_DIR="/var/www/11bychatgpt/data/uploads"
DB_NAME="fantasycricket"
DB_USER="fantasyapp"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MAX_BACKUPS=10  # Maximum number of backups to keep

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "===================================="
echo "  Starting backup process: $TIMESTAMP"
echo "===================================="

# Backup database
echo "[1/3] Creating database backup..."
pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/db_$TIMESTAMP.sql
if [ $? -eq 0 ]; then
    echo "Database backup created successfully: db_$TIMESTAMP.sql"
else
    echo "Error: Database backup failed!"
    exit 1
fi

# Backup uploads directory
echo "[2/3] Creating uploads backup..."
if [ -d "$UPLOADS_DIR" ]; then
    tar -czf $BACKUP_DIR/uploads_$TIMESTAMP.tar.gz $UPLOADS_DIR
    if [ $? -eq 0 ]; then
        echo "Uploads backup created successfully: uploads_$TIMESTAMP.tar.gz"
    else
        echo "Error: Uploads backup failed!"
        exit 1
    fi
else
    echo "Uploads directory does not exist, skipping backup"
fi

# Cleanup old backups
echo "[3/3] Cleaning up old backups..."
# Keep only the most recent MAX_BACKUPS number of database backups
ls -t $BACKUP_DIR/db_*.sql | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm
# Keep only the most recent MAX_BACKUPS number of uploads backups
ls -t $BACKUP_DIR/uploads_*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm

echo "Cleanup completed. Keeping the $MAX_BACKUPS most recent backups."

echo "===================================="
echo "  Backup process completed  "
echo "===================================="
echo ""
echo "Database backup: $BACKUP_DIR/db_$TIMESTAMP.sql"
echo "Uploads backup: $BACKUP_DIR/uploads_$TIMESTAMP.tar.gz"
echo ""
echo "To restore the database:"
echo "psql -U $DB_USER $DB_NAME < $BACKUP_DIR/db_$TIMESTAMP.sql"
echo ""
echo "To restore uploads:"
echo "tar -xzf $BACKUP_DIR/uploads_$TIMESTAMP.tar.gz -C /"
echo ""
echo "===================================="