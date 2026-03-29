#!/bin/bash
# ---------------------------------------------------------------------------
# 001-hashtagcms.sh — First-boot configuration for HashtagCMS
#
# This script runs ONCE via cloud-init (/var/lib/cloud/scripts/per-instance/)
# on the first time a Droplet is created from the marketplace snapshot.
#
# What it does:
#   1. Generates a secure random MySQL password
#   2. Creates the hashtagcms database and user
#   3. Updates /var/www/hashtagcms/.env with real credentials and Droplet IP
#   4. Generates the Laravel APP_KEY
#   5. Runs database migrations (seeds default CMS data)
#   6. Warms up Laravel caches
#   7. Writes credentials to /root/.digitalocean_passwords
#   8. Updates the MOTD to show the setup URL
#   9. Starts all services
#
# After this completes, the user simply visits http://<ip>/install
# to finish setup in a browser — just like WordPress.
# ---------------------------------------------------------------------------
set -euo pipefail

LOG_FILE="/var/log/hashtagcms-first-run.log"
exec > >(tee -a "$LOG_FILE") 2>&1

APP_DIR="/var/www/hashtagcms"
APP_USER="www-data"
CREDS_FILE="/root/.digitalocean_passwords"

echo "[$(date)] HashtagCMS first-run starting..."

# ---------------------------------------------------------------------------
# 1. Get Droplet public IP from metadata service
# ---------------------------------------------------------------------------
echo ">>> Fetching Droplet IP..."
DROPLET_IP=$(curl -s --max-time 10 http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address 2>/dev/null || hostname -I | awk '{print $1}')
echo "    IP: $DROPLET_IP"

# ---------------------------------------------------------------------------
# 2. Generate secure random credentials
# ---------------------------------------------------------------------------
echo ">>> Generating credentials..."
MYSQL_ROOT_PASS=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 24)
MYSQL_DB_PASS=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)
MYSQL_DB_NAME="hashtagcms"
MYSQL_DB_USER="hashtagcms"

# ---------------------------------------------------------------------------
# 3. Secure MySQL and create application database
# ---------------------------------------------------------------------------
echo ">>> Configuring MySQL..."
systemctl start mysql
sleep 3

# Set root password and secure the installation
mysql -u root << SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL

# Create app database and user
mysql -u root -p"${MYSQL_ROOT_PASS}" << SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB_NAME}\`.* TO '${MYSQL_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# Store root credentials for admin use
cat > /root/.my.cnf << CNF
[client]
user=root
password=${MYSQL_ROOT_PASS}
CNF
chmod 600 /root/.my.cnf

echo "    MySQL configured."

# ---------------------------------------------------------------------------
# 4. Update .env with real values
# ---------------------------------------------------------------------------
echo ">>> Updating .env..."
cd "$APP_DIR"

APP_URL="http://${DROPLET_IP}"

# Update each variable in place
sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|"          .env
sed -i "s|^APP_ENV=.*|APP_ENV=production|"           .env
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|"            .env
sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|"           .env
sed -i "s|^DB_PORT=.*|DB_PORT=3306|"                 .env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${MYSQL_DB_NAME}|" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${MYSQL_DB_USER}|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${MYSQL_DB_PASS}|" .env

echo "    .env updated."

# ---------------------------------------------------------------------------
# 5. Generate Laravel application key
# ---------------------------------------------------------------------------
echo ">>> Generating APP_KEY..."
php artisan key:generate --force --no-interaction
chown "$APP_USER":"$APP_USER" .env

# ---------------------------------------------------------------------------
# 6. Run database migrations (seeds default CMS data — Site, SiteProps, etc.)
# ---------------------------------------------------------------------------
echo ">>> Running migrations..."
php artisan migrate --force --no-interaction

# ---------------------------------------------------------------------------
# 7. Create storage symlink (in case it wasn't created during build)
# ---------------------------------------------------------------------------
if [ ! -L "$APP_DIR/public/storage" ]; then
  php artisan storage:link --no-interaction
fi

# ---------------------------------------------------------------------------
# 8. Warm up Laravel caches for production performance
# ---------------------------------------------------------------------------
echo ">>> Warming up caches..."
php artisan config:cache   --no-interaction
php artisan route:cache    --no-interaction
php artisan view:cache     --no-interaction
php artisan event:cache    --no-interaction

# Fix permissions after cache generation
chown -R "$APP_USER":"$APP_USER" "$APP_DIR/storage" "$APP_DIR/bootstrap/cache"

# ---------------------------------------------------------------------------
# 9. Start the Laravel queue worker via supervisor (if available) or cron
# ---------------------------------------------------------------------------
# Queue worker: process background jobs (email, imports, etc.)
if command -v supervisorctl &>/dev/null; then
  supervisorctl reread && supervisorctl update || true
else
  # Minimal cron fallback
  (crontab -l 2>/dev/null; echo "* * * * * cd $APP_DIR && php artisan schedule:run >> /dev/null 2>&1") | crontab -
fi

# ---------------------------------------------------------------------------
# 10. Write credentials file
# ---------------------------------------------------------------------------
echo ">>> Writing credentials to $CREDS_FILE..."
cat > "$CREDS_FILE" << CREDS
# HashtagCMS — First-Run Credentials
# Generated: $(date)
# Keep this file secure. You can delete it after noting the credentials.

DROPLET_IP=${DROPLET_IP}

MySQL Root Password : ${MYSQL_ROOT_PASS}
MySQL DB Name       : ${MYSQL_DB_NAME}
MySQL DB User       : ${MYSQL_DB_USER}
MySQL DB Password   : ${MYSQL_DB_PASS}

Setup URL  : http://${DROPLET_IP}/install
Admin URL  : http://${DROPLET_IP}/admin  (available after setup)
CREDS
chmod 600 "$CREDS_FILE"

# ---------------------------------------------------------------------------
# 11. Update MOTD
# ---------------------------------------------------------------------------
cat > /etc/motd << MOTD

*******************************************************************************
  HashtagCMS v3.0.1 — Powered by Laravel
*******************************************************************************

  Complete your setup in a browser:

    http://${DROPLET_IP}/install

  After setup:
    Admin panel  →  http://${DROPLET_IP}/admin
    Credentials  →  cat /root/.digitalocean_passwords

  Add a domain:
    1. Point your DNS A record to ${DROPLET_IP}
    2. Run: certbot --nginx -d yourdomain.com
    3. Update APP_URL in /var/www/hashtagcms/.env
    4. Run: php artisan config:cache

  Logs:
    Nginx  →  /var/log/nginx/error.log
    App    →  /var/www/hashtagcms/storage/logs/laravel.log

*******************************************************************************

MOTD

# ---------------------------------------------------------------------------
# 12. Start / restart services
# ---------------------------------------------------------------------------
echo ">>> Starting services..."
systemctl restart php8.3-fpm
systemctl restart nginx

echo "[$(date)] HashtagCMS first-run complete!"
echo "    Setup URL: http://${DROPLET_IP}/install"
