#!/bin/bash
# ---------------------------------------------------------------------------
# 01-base.sh — Install system packages, runtimes, and services
# Runs during Packer image build on a fresh Ubuntu 22.04 LTS droplet.
# ---------------------------------------------------------------------------
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> Updating system packages..."
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confold"

echo ">>> Installing prerequisites..."
apt-get install -y \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  git \
  unzip \
  zip \
  ufw \
  fail2ban \
  acl \
  cron \
  certbot \
  python3-certbot-nginx

# ---------------------------------------------------------------------------
# PHP 8.3 + extensions required by Laravel / HashtagCMS
# ---------------------------------------------------------------------------
echo ">>> Installing PHP 8.3..."
add-apt-repository -y ppa:ondrej/php
apt-get update -y
apt-get install -y \
  php8.3 \
  php8.3-fpm \
  php8.3-cli \
  php8.3-common \
  php8.3-mysql \
  php8.3-xml \
  php8.3-curl \
  php8.3-mbstring \
  php8.3-zip \
  php8.3-bcmath \
  php8.3-tokenizer \
  php8.3-fileinfo \
  php8.3-gd \
  php8.3-intl \
  php8.3-opcache \
  php8.3-pdo

echo ">>> Configuring PHP-FPM..."
PHP_INI="/etc/php/8.3/fpm/php.ini"
sed -i 's/^upload_max_filesize.*/upload_max_filesize = 100M/'   "$PHP_INI"
sed -i 's/^post_max_size.*/post_max_size = 100M/'               "$PHP_INI"
sed -i 's/^memory_limit.*/memory_limit = 256M/'                 "$PHP_INI"
sed -i 's/^max_execution_time.*/max_execution_time = 300/'      "$PHP_INI"
sed -i 's/^expose_php.*/expose_php = Off/'                      "$PHP_INI"

# Opcache tuning
PHP_CLI_INI="/etc/php/8.3/cli/php.ini"
for INI in "$PHP_INI" "$PHP_CLI_INI"; do
  sed -i 's/^;opcache.enable=.*/opcache.enable=1/'               "$INI"
  sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' "$INI"
  sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=20000/' "$INI"
  sed -i 's/^;opcache.validate_timestamps=.*/opcache.validate_timestamps=0/' "$INI"
done

# ---------------------------------------------------------------------------
# Nginx
# ---------------------------------------------------------------------------
echo ">>> Installing Nginx..."
apt-get install -y nginx

# ---------------------------------------------------------------------------
# MySQL 8.0
# ---------------------------------------------------------------------------
echo ">>> Installing MySQL 8.0..."
apt-get install -y mysql-server

# ---------------------------------------------------------------------------
# Node.js 20 LTS
# ---------------------------------------------------------------------------
echo ">>> Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# ---------------------------------------------------------------------------
# Composer (latest stable)
# ---------------------------------------------------------------------------
echo ">>> Installing Composer..."
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
  echo "ERROR: Invalid Composer installer checksum" >&2
  rm composer-setup.php
  exit 1
fi

php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# ---------------------------------------------------------------------------
# Enable services on boot
# ---------------------------------------------------------------------------
systemctl enable nginx
systemctl enable php8.3-fpm
systemctl enable mysql
systemctl enable fail2ban

# ---------------------------------------------------------------------------
# Firewall — allow SSH + HTTP/HTTPS
# ---------------------------------------------------------------------------
echo ">>> Configuring UFW..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'

echo ">>> 01-base.sh complete."
