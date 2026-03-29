#!/bin/bash
# ---------------------------------------------------------------------------
# 02-app.sh — Clone HashtagCMS, install PHP + JS dependencies, build assets
# Runs during Packer image build. DB is NOT configured yet (happens first-boot).
# ---------------------------------------------------------------------------
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

APP_DIR="/var/www/hashtagcms"
APP_USER="www-data"

echo ">>> Cloning HashtagCMS create-app..."
git clone --depth=1 https://github.com/hashtagcms/create-app.git "$APP_DIR"
cd "$APP_DIR"

# ---------------------------------------------------------------------------
# PHP dependencies
# ---------------------------------------------------------------------------
echo ">>> Installing Composer dependencies..."
composer install \
  --no-dev \
  --optimize-autoloader \
  --no-interaction \
  --prefer-dist

# ---------------------------------------------------------------------------
# Node.js / frontend assets
# ---------------------------------------------------------------------------
echo ">>> Installing npm dependencies and building assets..."
npm ci
npm run build

# Remove node_modules after build — saves ~300MB on the snapshot
rm -rf node_modules

# ---------------------------------------------------------------------------
# Environment file — placeholders replaced at first-boot by 001-hashtagcms.sh
# ---------------------------------------------------------------------------
echo ">>> Setting up .env..."
cp .env.example .env

# Set production-safe defaults (DB and APP_URL set at first-boot)
sed -i 's/^APP_ENV=.*/APP_ENV=production/'   .env
sed -i 's/^APP_DEBUG=.*/APP_DEBUG=false/'     .env
sed -i 's/^DB_HOST=.*/DB_HOST=127.0.0.1/'    .env
sed -i 's/^APP_URL=.*/APP_URL=__REPLACE_URL__/' .env

# ---------------------------------------------------------------------------
# Storage directories + symlink
# ---------------------------------------------------------------------------
echo ">>> Preparing storage directories..."
mkdir -p storage/logs
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p bootstrap/cache
php artisan storage:link --no-interaction || true

# ---------------------------------------------------------------------------
# File permissions
# ---------------------------------------------------------------------------
echo ">>> Setting file permissions..."
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
find "$APP_DIR" -type f -exec chmod 644 {} \;
find "$APP_DIR" -type d -exec chmod 755 {} \;
chmod -R 775 "$APP_DIR/storage"
chmod -R 775 "$APP_DIR/bootstrap/cache"
chmod 750 "$APP_DIR/artisan"

# ---------------------------------------------------------------------------
# Remove build artifacts not needed at runtime
# ---------------------------------------------------------------------------
rm -rf .git
rm -f package-lock.json

echo ">>> 02-app.sh complete."
