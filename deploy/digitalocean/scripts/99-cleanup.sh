#!/bin/bash
# ---------------------------------------------------------------------------
# 99-cleanup.sh — Sanitize the image before Packer takes a snapshot.
# DigitalOcean Marketplace requires images to be clean of secrets,
# SSH host keys, and temporary data so each Droplet gets a unique identity.
# ---------------------------------------------------------------------------
set -euo pipefail

echo ">>> Running final cleanup..."

# ---------------------------------------------------------------------------
# Stop services gracefully
# ---------------------------------------------------------------------------
systemctl stop nginx     || true
systemctl stop php8.3-fpm || true
# Keep MySQL stopped — first-boot script starts it

# ---------------------------------------------------------------------------
# Remove SSH host keys (regenerated on first Droplet boot)
# ---------------------------------------------------------------------------
rm -f /etc/ssh/ssh_host_*

# ---------------------------------------------------------------------------
# Remove cloud-init state so it re-runs on first boot
# ---------------------------------------------------------------------------
cloud-init clean --logs

# ---------------------------------------------------------------------------
# Clear logs
# ---------------------------------------------------------------------------
find /var/log -type f -exec truncate --size=0 {} \;
journalctl --vacuum-time=1s || true

# ---------------------------------------------------------------------------
# Clear shell history
# ---------------------------------------------------------------------------
unset HISTFILE
history -c
rm -f /root/.bash_history
rm -f /home/*/.bash_history

# ---------------------------------------------------------------------------
# Remove temporary/build artifacts
# ---------------------------------------------------------------------------
apt-get autoremove -y
apt-get clean
rm -rf /tmp/*
rm -rf /var/tmp/*

# Laravel: clear all caches (will be rebuilt on first-boot)
cd /var/www/hashtagcms
php artisan config:clear   || true
php artisan route:clear    || true
php artisan view:clear     || true
php artisan cache:clear    || true

# Clear Laravel logs
truncate --size=0 storage/logs/laravel.log || true

# ---------------------------------------------------------------------------
# Remove machine-specific identifiers
# ---------------------------------------------------------------------------
truncate --size=0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# ---------------------------------------------------------------------------
# Remove root authorized_keys (DO injects these per-Droplet from account)
# ---------------------------------------------------------------------------
rm -f /root/.ssh/authorized_keys

# ---------------------------------------------------------------------------
# Final filesystem sync
# ---------------------------------------------------------------------------
sync

echo ">>> 99-cleanup.sh complete. Image is ready for snapshot."
