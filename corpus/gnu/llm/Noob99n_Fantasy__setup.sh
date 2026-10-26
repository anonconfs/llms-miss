#!/bin/bash

# 11byChatGPT - Deployment Setup Script
# This script sets up the complete Fantasy Cricket application on a VPS
# Created by ChatGPT - April 2025

# Exit on error
set -e

echo "===================================="
echo "   11byChatGPT Deployment Setup    "
echo "===================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 
  exit 1
fi

# Ask for the zip file name
read -p "Please enter the name of your upload zip file (with .zip extension): " APP_ZIP_FILE

# Check if the file exists
if [ ! -f "$APP_ZIP_FILE" ]; then
    echo "Error: File $APP_ZIP_FILE not found!"
    echo "Please make sure the file exists in the current directory."
    exit 1
fi

# Update package lists
echo "[1/12] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required dependencies
echo "[2/12] Installing dependencies..."
apt-get install -y curl wget git nginx postgresql postgresql-contrib build-essential python3 python3-pip nodejs npm certbot python3-certbot-nginx ufw

# Setup Node.js 20.x
echo "[3/12] Setting up Node.js environment..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Create directory structure
echo "[4/12] Creating directory structure..."
mkdir -p /var/www/11bychatgpt/app
mkdir -p /var/www/11bychatgpt/owner
mkdir -p /var/www/11bychatgpt/data/uploads
mkdir -p /var/www/11bychatgpt/data/backups
mkdir -p /var/www/11bychatgpt/logs

# Set up PostgreSQL
echo "[5/12] Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE USER fantasyapp WITH PASSWORD 'fantasy123';"
sudo -u postgres psql -c "CREATE DATABASE fantasycricket;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE fantasycricket TO fantasyapp;"

# Configure environment variables
echo "[6/12] Setting up environment variables..."
cat > /var/www/11bychatgpt/.env << EOL
# Database Configuration
PGUSER=fantasyapp
PGPASSWORD=fantasy123
PGDATABASE=fantasycricket
PGHOST=localhost
DATABASE_URL=postgresql://fantasyapp:fantasy123@localhost:5432/fantasycricket

# App Configuration
NODE_ENV=production
SESSION_SECRET=$(openssl rand -hex 32)
OWNER_USERNAME=admin
OWNER_PASSWORD=admin123

# Email Configuration (Empty until configured)
SENDGRID_API_KEY=
EOL

# Configure nginx for main application (port 80)
echo "[7/12] Configuring Nginx for main application..."
cat > /etc/nginx/sites-available/11bychatgpt << EOL
server {
    listen 80;
    server_name 11bychatgpt.com www.11bychatgpt.com;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    location /uploads/ {
        alias /var/www/11bychatgpt/data/uploads/;
    }
    
    access_log /var/www/11bychatgpt/logs/access.log;
    error_log /var/www/11bychatgpt/logs/error.log;
}
EOL

# Configure nginx for owner panel (port 8080)
echo "[8/12] Configuring Nginx for owner panel..."
cat > /etc/nginx/sites-available/owner-11bychatgpt << EOL
server {
    listen 8080;
    server_name 11bychatgpt.com www.11bychatgpt.com;
    
    location / {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    access_log /var/www/11bychatgpt/logs/owner-access.log;
    error_log /var/www/11bychatgpt/logs/owner-error.log;
}
EOL

# Enable the sites
ln -sf /etc/nginx/sites-available/11bychatgpt /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/owner-11bychatgpt /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Setup systemd service for the main application
echo "[9/12] Setting up systemd service for main application..."
cat > /etc/systemd/system/11bychatgpt.service << EOL
[Unit]
Description=11byChatGPT Fantasy Cricket App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/11bychatgpt/app
EnvironmentFile=/var/www/11bychatgpt/.env
ExecStart=/usr/bin/npm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Setup systemd service for the owner panel
echo "[10/12] Setting up systemd service for owner panel..."
cat > /etc/systemd/system/11bychatgpt-owner.service << EOL
[Unit]
Description=11byChatGPT Fantasy Cricket Owner Panel
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/11bychatgpt/owner
EnvironmentFile=/var/www/11bychatgpt/.env
ExecStart=/usr/bin/npm start
Restart=on-failure
Environment=PORT=5001

[Install]
WantedBy=multi-user.target
EOL

# Setup backup script
echo "[11/12] Creating database backup script..."
cat > /var/www/11bychatgpt/data/backups/backup.sh << EOL
#!/bin/bash
BACKUP_DIR="/var/www/11bychatgpt/data/backups"
TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")

# Database backup
pg_dump -U fantasyapp fantasycricket > \$BACKUP_DIR/db_\$TIMESTAMP.sql

# Files backup
tar -czf \$BACKUP_DIR/uploads_\$TIMESTAMP.tar.gz /var/www/11bychatgpt/data/uploads

# Keep only the 10 most recent backups
ls -t \$BACKUP_DIR/db_*.sql | tail -n +11 | xargs -r rm
ls -t \$BACKUP_DIR/uploads_*.tar.gz | tail -n +11 | xargs -r rm

echo "Backup completed: \$TIMESTAMP"
EOL

chmod +x /var/www/11bychatgpt/data/backups/backup.sh

# Setup cron job for nightly backups
(crontab -l 2>/dev/null; echo "0 3 * * * /var/www/11bychatgpt/data/backups/backup.sh >> /var/www/11bychatgpt/logs/backup.log 2>&1") | crontab -

# Configure firewall
echo "[12/12] Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 8080/tcp
ufw --force enable

# Set correct permissions
chown -R www-data:www-data /var/www/11bychatgpt
chmod -R 755 /var/www/11bychatgpt

# Extract the uploaded ZIP file to app and owner directories
echo "[13/14] Extracting application files..."
TMP_DIR=$(mktemp -d)
unzip -q "$APP_ZIP_FILE" -d $TMP_DIR

# Check if the extracted content has app and owner folders
if [ -d "$TMP_DIR/app" ] && [ -d "$TMP_DIR/owner" ]; then
    # If app and owner folders exist, copy their contents
    cp -r $TMP_DIR/app/* /var/www/11bychatgpt/app/
    cp -r $TMP_DIR/owner/* /var/www/11bychatgpt/owner/
elif [ -d "$TMP_DIR/client" ] && [ -d "$TMP_DIR/server" ]; then
    # If it has client and server folders (like the development structure)
    # Set up main app directory
    cp -r $TMP_DIR/* /var/www/11bychatgpt/app/
    
    # Copy owner panel files if they exist
    if [ -d "$TMP_DIR/owner-control" ]; then
        cp -r $TMP_DIR/owner-control/* /var/www/11bychatgpt/owner/
    else
        echo "Warning: owner-control directory not found in zip file"
    fi
else
    # Assume everything is for the main app
    cp -r $TMP_DIR/* /var/www/11bychatgpt/app/
    echo "Warning: Could not find separate app/owner directories in the zip file"
    echo "Placed all files in the main app directory"
fi

# Clean up
rm -rf $TMP_DIR

# Install dependencies
echo "[14/14] Installing dependencies..."
cd /var/www/11bychatgpt/app
npm install --production

cd /var/www/11bychatgpt/owner
npm install --production

# Make production npm scripts
if [ ! -f "/var/www/11bychatgpt/app/package.json" ]; then
    echo "Error: package.json not found in app directory"
else
    # Ensure there's a start script in package.json for the main app
    if ! grep -q '"start"' /var/www/11bychatgpt/app/package.json; then
        # Add a start script if none exists
        sed -i 's/"scripts": {/"scripts": {\n    "start": "node server\/index.js",/g' /var/www/11bychatgpt/app/package.json
    fi
fi

if [ ! -f "/var/www/11bychatgpt/owner/package.json" ]; then
    echo "Creating package.json for owner panel"
    cat > /var/www/11bychatgpt/owner/package.json << EOL
{
  "name": "11bychatgpt-owner-panel",
  "version": "1.0.0",
  "description": "Owner panel for 11byChatGPT fantasy cricket app",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOL
    
    # Create a simple server for the owner panel if it doesn't exist
    if [ ! -f "/var/www/11bychatgpt/owner/index.js" ]; then
        cat > /var/www/11bychatgpt/owner/index.js << EOL
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 5001;

app.use(express.static(__dirname));

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(\`Owner panel running on port \${PORT}\`);
});
EOL
    fi
fi

# Set correct permissions
chown -R www-data:www-data /var/www/11bychatgpt
chmod -R 755 /var/www/11bychatgpt

# Restart services
systemctl daemon-reload
systemctl restart nginx
systemctl enable 11bychatgpt
systemctl enable 11bychatgpt-owner

echo "===================================="
echo "   Installation Complete!          "
echo "===================================="
echo ""
echo "Your Fantasy Cricket application is now set up!"
echo ""
echo "Main application: http://11bychatgpt.com"
echo "Owner panel: http://11bychatgpt.com:8080"
echo ""
echo "To secure your site with HTTPS, run:"
echo "certbot --nginx -d 11bychatgpt.com -d www.11bychatgpt.com"
echo ""
echo "Now upload your application files to:"
echo "/var/www/11bychatgpt/app/ (main application)"
echo "/var/www/11bychatgpt/owner/ (owner panel)"
echo ""
echo "Then start the services with:"
echo "systemctl start 11bychatgpt"
echo "systemctl start 11bychatgpt-owner"
echo ""
echo "===================================="