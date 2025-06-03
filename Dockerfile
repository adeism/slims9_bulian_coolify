# Gunakan image PHP resmi dengan Apache
FROM php:8.1-apache

# Set variabel lingkungan untuk konfigurasi non-interaktif
ENV DEBIAN_FRONTEND=noninteractive

# Install dependensi sistem
RUN apt-get update && apt-get install -y \
    apt-utils \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libonig-dev \
    unzip \
    git \
    imagemagick \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# Install ekstensi PHP yang dibutuhkan SLiMS
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo pdo_mysql mbstring gettext zip opcache intl exif

# Konfigurasi Apache
RUN a2enmod rewrite
COPY ./apache-slims.conf /etc/apache2/sites-available/000-default.conf

# Set direktori kerja
WORKDIR /var/www/html

# Salin kode sumber SLiMS ke dalam image
# Karena Dockerfile ada di root SLiMS, kita salin semuanya dari konteks build saat ini (.)
COPY . /var/www/html/

# Atur izin untuk direktori yang bisa ditulis SLiMS SETELAH menyalin file
# Direktori config perlu bisa ditulis oleh www-data untuk installer.
# Direktori lain untuk unggahan dan data runtime.
# Pastikan direktori config/database.sample.php disalin dengan benar sebelum installer dijalankan.
# Installer akan membuat config/database.php
RUN if [ ! -f /var/www/html/config/database.php ] && [ -f /var/www/html/config/database.sample.php ]; then \
        cp /var/www/html/config/database.sample.php /var/www/html/config/database.php; \
    fi \
    && chown -R www-data:www-data /var/www/html/config \
    && chown -R www-data:www-data /var/www/html/files \
    && chown -R www-data:www-data /var/www/html/images \
    && chown -R www-data:www-data /var/www/html/repository \
    && chmod -R 755 /var/www/html/config \
    && chmod -R 755 /var/www/html/files \
    && chmod -R 755 /var/www/html/images \
    && chmod -R 755 /var/www/html/repository

# Opsional: Sesuaikan pengaturan PHP jika diperlukan (mis., upload_max_filesize)
# Ini juga bisa diatur melalui environment variables di docker-compose.yml
RUN echo "upload_max_filesize = 64M" > /usr/local/etc/php/conf.d/custom-slims.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/custom-slims.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/custom-slims.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/custom-slims.ini

# Hapus direktori install SETELAH proses build untuk keamanan default.
# Pengguna harus menjalankan installer secara manual pada FQDN setelah deployment pertama,
# lalu trigger redeploy atau hapus manual via `docker exec` jika perlu.
# Untuk setup yang benar-benar otomatis, Anda memerlukan entrypoint script yang lebih kompleks.
RUN rm -rf /var/www/html/install
# CATATAN: Baris di atas dikomentari. Hapus direktori install secara manual atau melalui UI setelah instalasi pertama.

# Expose port Apache
EXPOSE 80

# Apache berjalan di foreground secara default dengan image dasar ini
# CMD ["apache2-foreground"] diwarisi
