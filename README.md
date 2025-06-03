# SLiMS Bulian Deployment with Coolify

This repository contains the SLiMS Bulian 9.6.1 source code and Docker configuration files for deploying it on a Coolify instance.

## Prerequisites

1.  A running Coolify instance.
2.  Git installed locally.
3.  SLiMS Bulian source code (version 9.6.1 is included in the `slims9_bulian-9.6.1/` directory of this repository).

## Repository Structure

```
.
├── slims9_bulian-9.6.1/     # SLiMS source code
├── Dockerfile               # Defines the SLiMS application image (PHP+Apache)
├── apache-slims.conf        # Apache virtual host configuration
├── docker-compose.yml       # Docker Compose file for Coolify
└── README.md                # This file
```

## Deployment Steps on Coolify

1.  **Push to Your Git Repository:**
    *   Clone this repository (or your fork).
    *   Ensure the `slims9_bulian-9.6.1/` directory contains the SLiMS source.
    *   Push the entire structure to your private or public Git repository (e.g., GitHub, GitLab).

2.  **Create a Database Service in Coolify:**
    *   In your Coolify dashboard, go to **Services**.
    *   Click **Add New Service** and choose **MariaDB** or **MySQL**.
    *   Configure the database (e.g., name it `slims-db`, choose a version like MariaDB 10.5+ or MySQL 8.0+).
    *   **Note down the service name** you gave it (e.g., `slims-db`). You'll need this for environment variables.

3.  **Create the SLiMS Application in Coolify:**
    *   Go to **Applications** in Coolify and click **Add New Application**.
    *   Choose **Build from a Git Repository**.
    *   Select your Git provider and repository.
    *   **Build Pack:** Select **Docker Compose**.
    *   **Docker Compose File Location:** `/docker-compose.yml` (assuming it's at the root of your Git repo).
    *   **Branch:** Select the branch you want to deploy (e.g., `main` or `master`).
    *   **Port Mappings:** Coolify usually auto-detects this. SLiMS runs on port 80 inside the container.
    *   Give your application a **Name** (e.g., `slims-app`).

4.  **Configure Environment Variables for SLiMS Application:**
    *   Go to your newly created SLiMS application in Coolify.
    *   Navigate to the **Environment Variables** tab.
    *   Add the following variables, replacing `your_coolify_db_service_name` with the actual name of the database service you created in step 2 (e.g., `slims-db`):
        *   `DB_HOST`: `${{service.your_coolify_db_service_name.host}}`
        *   `DB_NAME`: `${{service.your_coolify_db_service_name.database}}`
        *   `DB_USER`: `${{service.your_coolify_db_service_name.username}}`
        *   `DB_PASSWORD`: `${{service.your_coolify_db_service_name.password}}`
        *   `DB_PORT`: `${{service.your_coolify_db_service_name.port}}`
        *   `PHP_UPLOAD_MAX_FILESIZE`: `64M` (or your desired value)
        *   `PHP_POST_MAX_SIZE`: `64M` (or your desired value)
        *   `PHP_MEMORY_LIMIT`: `256M` (or your desired value)

5.  **Configure Domain & SSL:**
    *   Go to the **Domains** tab for your SLiMS application.
    *   Enter the FQDN (Fully Qualified Domain Name) you want to use (e.g., `slims.yourdomain.com`).
    *   Coolify will handle SSL certificate generation (usually via Let's Encrypt).

6.  **Deploy SLiMS Application:**
    *   Click the **Deploy** button for your SLiMS application.
    *   Monitor the build and deployment logs.

7.  **Run SLiMS Web Installer (First Time Only):**
    *   Once the deployment is successful, open your SLiMS FQDN in a web browser (e.g., `http://slims.yourdomain.com` or `https://slims.yourdomain.com`).
    *   You should be redirected to the SLiMS installer (`/install/index.php`).
    *   Follow the SLiMS installation steps:
        *   **Database Configuration:** The installer should pre-fill some details. Ensure they match the database credentials from your Coolify database service. If the `config/database.php` was not created automatically by an entrypoint script (this setup doesn't include one for now, relying on the installer), you'll need to provide them. However, the environment variables set in Coolify *should* be available to the PHP process if SLiMS's installer or `database.sample.php` is designed to pick them up.
            *   For this setup, the SLiMS installer will directly write to `config/database.php`. This file will be persisted thanks to the `slims_config` volume.
        *   **Admin User:** Create your SLiMS administrator account.
    *   After successful installation, SLiMS will instruct you to **delete the `install` directory**.

8.  **Secure SLiMS - Remove `install` Directory:**
    *   **Option 1 (Manual - for immediate security):**
        1.  SSH into your Coolify server.
        2.  Find your SLiMS container ID: `docker ps | grep your_slims_app_name`
        3.  Access the container: `docker exec -it <container_id> bash`
        4.  Remove the install directory: `rm -rf /var/www/html/install`
        5.  Exit the container: `exit`
    *   **Option 2 (Permanent - Recommended after first install):**
        1.  Modify your `Dockerfile`. After the `COPY ./slims9_bulian-9.6.1/ /var/www/html/` line, add:
            ```dockerfile
            RUN rm -rf /var/www/html/install
            ```
        2.  Commit and push this change to your Git repository.
        3.  Redeploy your SLiMS application in Coolify. This will rebuild the image without the `install` directory. Your `config/database.php` (created by the installer) will be preserved by the `slims_config` volume.

## Persistent Data

Coolify manages the following Docker volumes for SLiMS:
*   `slims_config`: Stores `config/database.php` and other configuration files.
*   `slims_files`: Stores files uploaded via SLiMS (e.g., digital attachments).
*   `slims_images`: Stores cover images and other SLiMS-managed images.
*   `slims_repository`: For SLiMS's file repository features.

These volumes ensure your data persists across deployments and updates.

## Troubleshooting

*   Check Coolify's deployment logs for any build or runtime errors.
*   Verify environment variables are correctly set and accessible by the SLiMS application.
*   Ensure file/directory permissions within the container are correct for `www-data`.
*   If the installer doesn't see the database, double-check the `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `DB_PORT` environment variables in Coolify and ensure they match the details of your Coolify-managed database service.
```

---

**Explanation and Coolify Context:**

1.  **`Dockerfile`:**
    *   Uses `php:8.1-apache` as a base, providing PHP and Apache.
    *   Installs necessary PHP extensions for SLiMS.
    *   Copies SLiMS source code.
    *   Sets `www-data` permissions for writable directories. The `config` directory is made writable so the SLiMS installer can create/modify `database.php`.
    *   Includes an `apache-slims.conf` to ensure `AllowOverride All` is set, which SLiMS often relies on for `.htaccess` files (though it's better to centralize Apache config).

2.  **`docker-compose.yml`:**
    *   Defines a single service `slims_app`.
    *   `build: .` tells Coolify to build the image using the `Dockerfile` in the current directory.
    *   **Volumes:** This is crucial.
        *   `slims_config:/var/www/html/config`: The SLiMS installer will create/modify `config/database.php`. This volume ensures that file persists across container restarts/redeployments.
        *   `slims_files`, `slims_images`, `slims_repository`: These are standard SLiMS directories for user-uploaded content and need to be persistent.
    *   **Environment Variables:**
        *   `DB_HOST`, `DB_NAME`, etc.: These use Coolify's service discovery templating (`${{service.YOUR_DB_SERVICE_NAME_IN_COOLIFY.host}}`). You **must** replace `your_coolify_db_service_name` with the actual name you give to your database service when you create it in Coolify. SLiMS's `database.sample.php` uses placeholders like `_DB_HOST_`. The SLiMS installer will ask for these details, and it will write them into `config/database.php`.
        *   PHP settings are included as environment variables, which the PHP-Apache base image often respects.

3.  **SLiMS Installation:**
    *   On the first deployment, you will navigate to `yourdomain.com/install/`.
    *   The SLiMS installer will guide you. For database details, you'll use the credentials of the database service you created in Coolify.
    *   The installer writes to `config/database.php`. Because `/var/www/html/config` is a volume, this file will persist.

4.  **Post-Installation:**
    *   It is **critical** to remove the `install/` directory from SLiMS after installation for security. The README provides two methods. The Dockerfile modification is the more robust, permanent solution after the initial setup.

This setup should allow you to get SLiMS Bulian running on Coolify. Remember to adapt the database service name in the `docker-compose.yml` environment variables.
