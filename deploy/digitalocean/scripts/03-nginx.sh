#!/bin/bash
# ---------------------------------------------------------------------------
# 03-nginx.sh — Configure Nginx for HashtagCMS (Laravel)
# Runs during Packer image build.
# ---------------------------------------------------------------------------
set -euo pipefail

echo ">>> Configuring Nginx..."

# Remove default site
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# ---------------------------------------------------------------------------
# Main site config — serves on port 80 (Certbot adds HTTPS block at runtime)
# ---------------------------------------------------------------------------
cat > /etc/nginx/sites-available/hashtagcms << 'NGINX_CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    root /var/www/hashtagcms/public;
    index index.php;

    charset utf-8;
    client_max_body_size 100M;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN"             always;
    add_header X-Content-Type-Options "nosniff"          always;
    add_header X-XSS-Protection "1; mode=block"          always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Laravel front-controller
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    # PHP-FPM
    location ~ \.php$ {
        fastcgi_pass   unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_hide_header X-Powered-By;
        fastcgi_read_timeout 300;
    }

    # Block access to hidden files except .well-known (Let's Encrypt)
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Long-lived cache for compiled assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)$ {
        expires max;
        log_not_found off;
        access_log off;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1024;
}
NGINX_CONF

# Enable site
ln -sf /etc/nginx/sites-available/hashtagcms /etc/nginx/sites-enabled/hashtagcms

# ---------------------------------------------------------------------------
# Global Nginx tweaks
# ---------------------------------------------------------------------------
# Hide Nginx version
sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

# Adjust worker_processes to auto
sed -i 's/worker_processes .*/worker_processes auto;/' /etc/nginx/nginx.conf

# ---------------------------------------------------------------------------
# Validate config
# ---------------------------------------------------------------------------
nginx -t

echo ">>> 03-nginx.sh complete."
