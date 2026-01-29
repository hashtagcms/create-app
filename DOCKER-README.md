# 🐳 Docker Development Environment - HashtagCMS

This document provides technical details for developers using the Dockerized environment for the HashtagCMS Starter Kit.

[⬅️ Back to main README.md](README.md)

---

## 🚀 Getting Started

Follow these steps to initialize your development environment:

### 1. Configure Services (Optional)
Before starting, you can customize the environment in `docker-compose.yml`:
- **Database**: Check the `db` service environment variables (`MYSQL_DATABASE`, `MYSQL_USER`, etc.).
- **Storage**: Database persistence is mapped to `./docker/mysql`. Application code is mounted to `/var/www`.
- **Networking**: All containers are joined to `hashtagcms-network`.

### 2. Verify Environment Alignment
Ensure your `.env` settings (based on `.env.example`) align with the Docker service discovery names:
- **DB_HOST**: Should be `db` (the service name in docker-compose).
- **DB_PORT**: `3306`.
- **APP_URL**: `http://localhost:8081`.

### 3. Launch the Environment
Run the following command to build the images and start the containers in the background:
```bash
docker-compose up -d --build
```

### 4. ✨ The "Magic" Command (CRITICAL)
> [!NOTE]
> Steps 4 and 5 are only required during the **initial installation**.

After verifying your environment, you **must** run the HashtagCMS installer inside the container to seed your database and set up the admin credentials. This is the most important step to get the CMS fully operational:

```bash 
docker exec -it hashtagcms-app php artisan cms:install
```

### 5. Installation Wizard
Once the containers are running and healthy, visit the installation wizard in your browser to check your environment:
[http://localhost:8081/install](http://localhost:8081/install)


> [!IMPORTANT]
> This command handles database migrations, seeds core data, and prompts you to create your Super Admin account. Without this, your database will be empty and you won't be able to log in to `/admin`.

---

## 🏗 System Architecture

The environment is orchestrated using **Docker Compose** and consists of three primary services running on a dedicated bridge network:

1.  **`web` (Nginx)**: Alpine-based Nginx acting as a reverse proxy.
2.  **`app` (PHP-FPM)**: Customized PHP 8.4 image with Laravel-required extensions (pdo_mysql, gd, zip, etc.).
3.  **`db` (MySQL 8.0)**: Relational database storage.

---

## 🔧 Using Existing External Services

If you already have a MySQL database or an Nginx reverse proxy running on your host machine or in separate containers, you can adapt this setup:

### 1. Using your own MySQL
If you want to use a database running outside this docker-compose project:
- **Deactivate the `db` service**: Comment out or remove the `db` block in `docker-compose.yml`.
- **Update `.env`**: Point `DB_HOST` to your database address. Use `host.docker.internal` if the database is running directly on your Mac host (outside Docker).
- **Connectivity**: Ensure your database is listening for connections from the Docker network IP range.

### 2. Using your own Nginx
If you use a global reverse proxy (like Nginx Proxy Manager or Traefik):
- **Disable the `web` service**: You can remove the `web` service from `docker-compose.yml`.
- **FastCGI Connection**: Point your external Nginx configuration to the `app` container on port `9000`. You may need to join the `app` service to your existing external network.

---

## 📄 Application-Only Example

For a "lean" setup where only the application engine runs in Docker, see the provided **`docker-compose.app-only.yml`** file. You can run it using:

```bash
docker-compose -f docker-compose.app-only.yml up -d
```

---

### 🔌 Networking & Service Discovery
All services are connected to the `hashtagcms-network`. Services communicate with each other using their **Service Names** as hostnames:
- PHP connects to MySQL using `DB_HOST=db`.
- Nginx proxies PHP requests to `fastcgi_pass app:9000`.

#### Customizing Discovery
If you need to change hostnames or connect to external services:
- **Service Name Change**: Renaming a service in `docker-compose.yml` (e.g., changing `db` to `mysql-prod`) will change its hostname address.
- **Aliases**: You can add `aliases` under the network configuration for a service to make it reachable via multiple names.
- **External Networks**: To connect to a pre-existing Docker network (e.g., a shared reverse proxy), define the network as `external: true` in the `networks` block.

---

## 💾 Storage & Persistence

### 1. Application Code (Bind Mount)
The root project directory is bind-mounted to `/var/www` in both the `app` and `web` containers. 
- **Hot Reloading**: Any changes made on the host machine are reflected instantly in the container.
- **Permissions**: The `app` container runs as the `www-data` user. The Dockerfile ensures following permissions are set for Laravel:
  - `storage/` and `bootstrap/cache/` must remain writable by the container.

### 2. Database Persistence
MySQL data is persisted on the host machine at `./docker/mysql`. 

> [!CAUTION]
> **Data Persistence Warning**: Always ensure the MySQL data path is mapped to a volume outside the container (as configured in `docker-compose.yml`). If you remove this mapping, all your database records will be permanently lost when the container is deleted or recreated.

- **Volume Type**: Bind mount.
- **Benefit**: You can destroy and recreate containers without losing your database state.
- **Initialization**: Any `.sql` or `.sh` files placed in `./docker/mysql/init` (standard MySQL image behavior) will be executed on the first run.

---

## 🚀 Environment Bootstrap (`entrypoint.sh`)

To minimize manual setup, the `app` container uses a custom entrypoint script (`docker/entrypoint.sh`) that executes the following on startup:

1.  **Environment Sync**: Checks for `.env`. If missing, copies `.env.example`.
2.  **Dependency Management**: Runs `composer install` if the `vendor/` directory is missing.
3.  **App Key**: Generates the `APP_KEY` if it hasn't been set.
4.  **Storage Link**: Executes `php artisan storage:link` if the symbolic link is missing.
5.  **Runtime**: Hands over execution to `php-fpm`.

---

## 🛠 Developer Cheat Sheet

### Starting the Environment
```bash
docker-compose up -d --build
```

### Helper Script (The Easy Way)
We've included a `./cms` helper script to run commands without typing long Docker strings:

```bash
./cms build              # 🏗 Build/Rebuild and start containers

./cms artisan cms:install # Run just the installer

./cms fresh              # 💣 Wipe everything and start a fresh install
```

### Checking Logs
```bash
docker-compose logs -f app
```

### 💣 Resetting to Fresh Install (One Command)
You can now reset your entire environment to a blank state and trigger the re-installation with a single command:

```bash
./cms fresh
```
*This will kill any conflicting port processes, stop containers, wipe the database and .env, rebuild, and start the installer.*

---
### Rebuilding for Dependency Changes
If you modify the `Dockerfile` or need to force a clean build, simply run:
```bash
./cms build
```

---

## ⚙️ MySQL Configuration Reference

When running the HashtagCMS installer at `http://localhost:8081/install`, use the following credentials:

| Key | Value |
| :--- | :--- |
| **Connection** | `mysql` |
| **Host** | `db` |
| **Port** | `3306` |
| **Database** | `hashtagcms` |
| **Username** | `hashtagcms` |
| **Password** | `root` |

---

## 🏗 Extending the Environment

This setup is designed to be modular. You can easily add services to the `docker-compose.yml`:

-   **Redis**: For high-performance caching and session management.
-   **Mailpit**: To intercept and view outgoing emails in a local web UI.
-   **Node.js**: To containerize frontend asset compilation (`npm run dev`), making the project truly zero-dependency on the host machine.
-   **Xdebug**: For step-debugging PHP code directly in VS Code.

---

---

## 🛠 Troubleshooting

### Port Already Allocated (Error: `Bind for 0.0.0.0:3306 failed`)
If you see an error stating a port is already in use, it means another service (like a local MySQL or Nginx) is already using that port. You can easily switch to a different port without editing the YAML files.

**Solution: Override ports via environment variables:**

```bash
# Example: Use port 8081 for Web and 3307 for Database
WEB_PORT=8081 DB_PORT_EXTERNAL=3307 docker-compose up -d
```

Valid variables you can override:
- `WEB_PORT` (Default: `8081`)
- `DB_PORT_EXTERNAL` (Default: `3306`)
- `APP_PORT` (Default: `9000` - for app-only setup)
- `APP_CONTAINER_NAME` (Default: `hashtagcms-app`)
- `WEB_CONTAINER_NAME` (Default: `hashtagcms-web`)
- `DB_CONTAINER_NAME` (Default: `hashtagcms-db`)

---

### Customizing Container Names
If you want to run multiple instances of HashtagCMS on the same machine, you **must** give them unique container names.

```bash
# Example: Running a second instance called 'blog-project'
APP_CONTAINER_NAME=blog-app WEB_CONTAINER_NAME=blog-web WEB_PORT=8081 docker-compose up -d
```

## 🔒 Production Considerations
This setup is optimized for **development**. For production deployment:
1.  **Asset Compilation**: Use a multi-stage Dockerfile to compile assets via `npm run build` and serve static files via Nginx.
2.  **ReadOnly Filesystem**: Consider making the application code read-only in production, except for `storage/`.
3.  **Secrets**: Use Docker Secrets or environment-level secret management instead of `.env` files.
