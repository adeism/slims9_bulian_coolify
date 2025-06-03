# SLiMS Bulian Deployment dengan Coolify

Repositori ini berisi kode sumber SLiMS Bulian (diasumsikan Anda telah melakukan fork dari repositori resmi dan menambahkan file-file Docker ini ke root) beserta konfigurasi Docker untuk melakukan deployment pada instance Coolify.

## Prasyarat

1.  Instance Coolify yang berjalan.
2.  Git terinstal secara lokal.
3.  Anda telah melakukan fork repositori SLiMS Bulian (misalnya, `slims/slims9_bulian` atau yang relevan) ke akun Git Anda.
4.  File `Dockerfile`, `docker-compose.yml`, dan `apache-slims.conf` dari panduan ini telah ditambahkan ke *root* repositori SLiMS hasil fork Anda.

## Struktur Repositori (Setelah Fork dan Penambahan File)

```
. (ROOT REPOSITORI SLIMS YANG SUDAH ANDA FORK)
├── admin/
├── config/
│   └── database.sample.php
├── files/
├── ... (file & folder SLiMS lainnya)
│
├── Dockerfile               <-- File dari panduan ini
├── docker-compose.yml       <-- File dari panduan ini
└── apache-slims.conf        <-- File dari panduan ini
```

## Langkah-Langkah Deployment di Coolify

1.  **Commit & Push ke Repositori Git Anda:**
    *   Pastikan semua file (`Dockerfile`, `docker-compose.yml`, `apache-slims.conf`) telah ditambahkan ke root repositori SLiMS hasil fork Anda.
    *   Commit dan push perubahan tersebut ke repositori Git Anda (misalnya, GitHub, GitLab).

2.  **Buat Aplikasi Baru di Coolify:**
    *   Masuk ke dashboard Coolify Anda.
    *   Pilih **Applications** > **Add New Application**.
    *   Pilih **Build from a Git Repository**.
    *   Hubungkan Coolify dengan penyedia Git Anda dan pilih repositori SLiMS hasil fork Anda.
    *   **Build Pack:** Pilih **Docker Compose**.
    *   **Docker Compose File Location:** Biarkan default (`/docker-compose.yml`), karena file tersebut ada di root repositori Anda.
    *   **Branch:** Pilih branch yang ingin Anda deploy (misalnya, `main` atau `master`).
    *   **Nama Layanan Aplikasi:** Coolify akan meminta Anda memberi nama untuk layanan ini (misalnya, `slims-app`). Ini akan menjadi nama layanan `slimsapp` yang ada di `docker-compose.yml` Anda.
    *   **Nama Layanan Database:** Layanan `mariadb` yang didefinisikan dalam `docker-compose.yml` juga akan dibuat oleh Coolify. Anda bisa melihatnya sebagai bagian dari stack aplikasi Anda.

3.  **Konfigurasi Environment Variables (Penting!):**
    *   Setelah aplikasi dibuat di Coolify, navigasikan ke layanan `slimsapp` Anda.
    *   Buka tab **Environment Variables**.
    *   Coolify seharusnya sudah mendeteksi variabel lingkungan dari `docker-compose.yml`.
    *   Variabel `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, dan `DB_PORT` untuk layanan `slimsapp` akan **secara otomatis diisi oleh Coolify** dengan nilai-nilai dari layanan `mariadb` yang juga didefinisikan dalam `docker-compose.yml`. Anda tidak perlu mengisinya secara manual jika `docker-compose.yml` Anda sudah benar.
    *   **SANGAT PENTING:** Untuk layanan `mariadb`, Anda **HARUS** mengatur nilai yang aman untuk `MARIADB_ROOT_PASSWORD` dan `MARIADB_PASSWORD` (serta `MARIADB_USER` dan `MARIADB_DATABASE` jika Anda ingin berbeda dari default). Anda bisa melakukannya melalui UI Coolify di bagian environment variables untuk layanan `mariadb` tersebut. **Jangan gunakan password default di produksi!**

4.  **Konfigurasi Domain & SSL:**
    *   Masih di pengaturan aplikasi `slimsapp` Anda di Coolify, buka tab **Domains**.
    *   Masukkan FQDN (Fully Qualified Domain Name) yang ingin Anda gunakan untuk SLiMS (misalnya, `slims.domainanda.com`).
    *   Coolify akan menangani pembuatan sertifikat SSL (biasanya via Let's Encrypt).

5.  **Deploy Aplikasi:**
    *   Klik tombol **Deploy** untuk aplikasi `slimsapp` Anda.
    *   Pantau log build dan deployment di Coolify. Proses ini akan membangun image Docker dari `Dockerfile` Anda dan kemudian menjalankan layanan `slimsapp` dan `mariadb` sesuai `docker-compose.yml`.

6.  **Jalankan Web Installer SLiMS (Hanya untuk Pertama Kali):**
    *   Setelah deployment berhasil, buka FQDN SLiMS Anda di browser (misalnya, `https://slims.domainanda.com`).
    *   Anda akan diarahkan ke halaman instalasi SLiMS (`/install/index.php`).
    *   Ikuti langkah-langkah instalasi SLiMS:
        *   **Konfigurasi Database:**
            *   **Host Database:** `mariadb` (sesuai nama layanan di `docker-compose.yml`).
            *   **Nama Database:** Isi dengan nilai yang Anda set untuk `MARIADB_DATABASE` (misalnya, `slims_db`).
            *   **User Database:** Isi dengan nilai `MARIADB_USER` (misalnya, `slims_user`).
            *   **Password Database:** Isi dengan nilai `MARIADB_PASSWORD`.
            *   **Port Database:** `3306`.
        *   **Admin SLiMS:** Buat akun administrator untuk SLiMS.
    *   Setelah instalasi berhasil, SLiMS akan meminta Anda untuk **menghapus direktori `install`**.

7.  **Hapus Direktori `install` (SANGAT PENTING):**
    *   **Opsi 1 (Manual - untuk keamanan segera):**
        1.  Gunakan fitur "Open Remote Terminal" di Coolify untuk layanan `slimsapp`.
        2.  Jalankan perintah: `rm -rf /var/www/html/install`
        3.  Restart aplikasi SLiMS dari UI Coolify jika perlu.
    *   **Opsi 2 (Permanen - Direkomendasikan setelah instalasi pertama berhasil):**
        1.  Pada file `Dockerfile` Anda, hapus komentar pada baris:
            ```dockerfile
            # RUN rm -rf /var/www/html/install
            ```
            menjadi:
            ```dockerfile
            RUN rm -rf /var/www/html/install
            ```
        2.  Commit dan push perubahan `Dockerfile` ini ke repositori Git Anda.
        3.  Redeploy aplikasi SLiMS Anda di Coolify. Ini akan membangun image baru tanpa direktori `install`. File `config/database.php` yang dibuat oleh installer akan tetap ada karena disimpan di volume `slims_config`.

## Data Persisten

Coolify akan mengelola volume Docker berikut untuk SLiMS, memastikan data Anda aman:
*   `slims_config`: Menyimpan `config/database.php` dan file konfigurasi lainnya.
*   `slims_files`: Menyimpan file yang diunggah melalui SLiMS (misalnya, lampiran digital).
*   `slims_images`: Menyimpan gambar sampul dan gambar lain yang dikelola SLiMS.
*   `slims_repository`: Untuk fitur repositori file SLiMS.
*   `slims_mariadb_data`: Menyimpan semua data dari database MariaDB.

## Pemecahan Masalah

*   Periksa log deployment di Coolify untuk kesalahan build atau runtime.
*   Pastikan variabel lingkungan untuk koneksi database di layanan `slimsapp` sudah benar dan menunjuk ke detail layanan `mariadb`.
*   Verifikasi izin file/direktori di dalam container (`config/`, `files/`, `images/`, `repository/`) sudah benar untuk user `www-data`.
*   Jika installer SLiMS tidak bisa terhubung ke database, periksa kembali konfigurasi `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, dan `DB_PORT` yang digunakan SLiMS saat proses instalasi. Pastikan sesuai dengan yang diatur untuk layanan `mariadb` di Coolify.
```

---

**Poin Penting:**

*   **Password Database:** Pastikan Anda mengganti password default (`RootP@$$wOrdCoolify` dan `P@$$wOrdCoolify`) di `docker-compose.yml` dengan password yang kuat dan aman, atau lebih baik lagi, atur melalui UI Coolify.
*   **Direktori `install`:** Sangat krusial untuk menghapus direktori `install/` setelah instalasi SLiMS pertama berhasil.
*   **Penyesuaian `Dockerfile`:** Jika Anda perlu menginstal ekstensi PHP tambahan atau dependensi sistem lain untuk plugin SLiMS tertentu, Anda bisa menambahkannya di `Dockerfile`.
*   **Coolify Service Names:** Nama layanan di `docker-compose.yml` (`slimsapp` dan `mariadb`) digunakan untuk komunikasi internal antar container. Coolify akan memberi Anda opsi untuk memberi nama layanan secara keseluruhan di UI-nya (ini yang akan muncul di daftar aplikasi/layanan Anda di Coolify). Variabel seperti `${{service.mariadb.host}}` akan merujuk pada nama layanan internal (`mariadb`) yang didefinisikan di compose file.

Semoga ini memberikan panduan yang lengkap!
