#!/bin/bash

# 11byChatGPT - Basic Deployment Setup Script
# This script sets up the basic structure for the Fantasy Cricket application
# Created by ChatGPT - April 2025

# Exit on error
set -e

echo "===================================="
echo "   11byChatGPT Basic Deployment    "
echo "===================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 
  exit 1
fi

# Check if directory is provided
EXTRACTED_DIR=$1
if [ -z "$EXTRACTED_DIR" ]; then
  read -p "Enter the path to your extracted FantasyCricketChamp directory: " EXTRACTED_DIR
fi

# Check if the directory exists
if [ ! -d "$EXTRACTED_DIR" ]; then
  echo "Error: Directory $EXTRACTED_DIR does not exist!"
  exit 1
fi

# Create directory structure
echo "[1/9] Creating directory structure..."
mkdir -p /var/www/11bychatgpt/app
mkdir -p /var/www/11bychatgpt/owner
mkdir -p /var/www/11bychatgpt/data/uploads
mkdir -p /var/www/11bychatgpt/data/backups
mkdir -p /var/www/11bychatgpt/logs

# Set up PostgreSQL
echo "[2/9] Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE USER fantasyapp WITH PASSWORD 'fantasy123';"
sudo -u postgres psql -c "CREATE DATABASE fantasycricket;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE fantasycricket TO fantasyapp;"

# Configure environment variables
echo "[3/9] Setting up environment variables..."
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
echo "[4/9] Configuring Nginx for main application..."
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
echo "[5/9] Configuring Nginx for owner panel..."
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
echo "[6/9] Setting up systemd service for main application..."
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
echo "[7/9] Setting up systemd service for owner panel..."
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

# Copy application files
echo "[8/9] Copying application files..."

# Copy main application files
if [ -d "$EXTRACTED_DIR/client" ] && [ -d "$EXTRACTED_DIR/server" ]; then
    echo "Found standard project structure, copying files..."
    
    # Copy to app directory
    cp -r $EXTRACTED_DIR/* /var/www/11bychatgpt/app/
    
    # Copy owner panel if it exists
    if [ -d "$EXTRACTED_DIR/owner-control" ]; then
        echo "Found owner panel files, copying..."
        cp -r $EXTRACTED_DIR/owner-control/* /var/www/11bychatgpt/owner/
    else
        echo "Warning: Owner panel directory not found"
        echo "Creating a basic owner panel..."
        
        # Create minimal owner panel files
        cat > /var/www/11bychatgpt/owner/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>11byChatGPT - Owner Panel</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        h1 { color: #333; }
        .message { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 10px; border-radius: 4px; }
    </style>
</head>
<body>
    <h1>11byChatGPT Owner Panel</h1>
    <div class="message">
        <p>Owner panel files were not found in the extracted directory.</p>
        <p>Please upload the correct files to the server at: /var/www/11bychatgpt/owner/</p>
    </div>
</body>
</html>
EOL

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
else
    echo "Error: Expected directory structure not found!"
    echo "Looking for client/ and server/ directories in $EXTRACTED_DIR"
    exit 1
fi

# Configure package.json and install dependencies
echo "[9/9] Setting up dependencies..."

# Main app
cd /var/www/11bychatgpt/app

# Add start script to package.json if needed
if ! grep -q '"start"' package.json; then
    sed -i 's/"scripts": {/"scripts": {\n    "start": "node server\/index.js",/g' package.json
fi

# Install dependencies
npm install --production

# Owner panel
cd /var/www/11bychatgpt/owner
npm install --production

# Set proper permissions
chown -R www-data:www-data /var/www/11bychatgpt
chmod -R 755 /var/www/11bychatgpt

# Configure firewall
echo "Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 8080/tcp
ufw --force enable

# Restart services
systemctl daemon-reload
systemctl restart nginx
systemctl enable 11bychatgpt
systemctl start 11bychatgpt
systemctl enable 11bychatgpt-owner
systemctl start 11bychatgpt-owner

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
echo "===================================="