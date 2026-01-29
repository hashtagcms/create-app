#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
fi

# Install composer dependencies if vendor directory is missing
if [ ! -d vendor ]; then
    echo "Installing composer dependencies..."
    composer install --no-interaction --optimize-autoloader
fi

# Generate app key if not set
if ! grep -q "APP_KEY=base64:" .env; then
    echo "Generating app key..."
    php artisan key:generate
fi

# Create storage link if it doesn't exist
if [ ! -e public/storage ]; then
    echo "Creating storage symbolic link..."
    php artisan storage:link
elif [ ! -L public/storage ]; then
    echo "Warning: public/storage exists but is not a symbolic link. Skipping storage:link."
fi

# Wait for database to be ready (optional but recommended)
# This is a simple check, can be improved
# echo "Waiting for database..."
# sleep 10

# Run migrations (careful with this in production, but good for fresh installs)
# php artisan migrate --force

# Start PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm
