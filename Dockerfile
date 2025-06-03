# Use an official PHP image with Apache
FROM php:8.1-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libonig-dev \ # For mbstring
    unzip \
    git \
    imagemagick \ # For image processing if needed by some SLiMS features/plugins
    ghostscript \  # For PDF thumbnail generation if needed
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by SLiMS
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo pdo_mysql mbstring gettext zip opcache intl exif

# Configure Apache
RUN a2enmod rewrite
COPY ./apache-slims.conf /etc/apache2/sites-available/000-default.conf

# Set working directory
WORKDIR /var/www/html

# Copy SLiMS source code into the image
# IMPORTANT: Make sure 'slims9_bulian-9.6.1' directory is at the same level as this Dockerfile
COPY ./slims9_bulian-9.6.1/ /var/www/html/

# Set permissions for SLiMS writable directories AFTER copying files
# The config directory needs to be writable by www-data for the installer.
# Other directories are for uploads and runtime data.
RUN chown -R www-data:www-data /var/www/html/config \
    && chown -R www-data:www-data /var/www/html/files \
    && chown -R www-data:www-data /var/www/html/images \
    && chown -R www-data:www-data /var/www/html/repository

# Optional: Adjust PHP settings if needed (e.g., upload_max_filesize)
RUN echo "upload_max_filesize = 64M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini

# Expose Apache port
EXPOSE 80

# Apache runs in foreground by default with this base image
# CMD ["apache2-foreground"] is inherited
