# Gunakan image PHP resmi dengan Apache
FROM php:8.1-apache

# Set variabel lingkungan untuk konfigurasi non-interaktif
ENV DEBIAN_FRONTEND=noninteractive
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Install dependensi sistem
# apt-utils untuk mengurangi beberapa warning saat instalasi paket
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
# Mengaktifkan modul rewrite dan menyalin konfigurasi virtual host kustom
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
# Ini juga akan menyalin database.sample.php ke database.php jika database.php belum ada,
# yang mana akan di-overwrite oleh installer atau volume.
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
# PENTING: Jika Anda menjalankan ini untuk pertama kali, Anda perlu mengomentari baris ini,
# deploy, jalankan installer SLiMS, lalu uncomment baris ini dan deploy ulang.
# Atau, hapus secara manual dari container setelah instalasi.
RUN rm -rf /var/www/html/install

# Expose port Apache
EXPOSE 80

# Apache berjalan di foreground secara default dengan image dasar ini
# CMD ["apache2-foreground"] diwarisi
