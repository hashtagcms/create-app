
<p align="center">
    <a href="https://www.hashtagcms.org" target="_blank">
        <img src="public/assets/hashtagcms/be/modern/img/logo.png" width="300" alt="HashtagCMS Logo">
    </a>
</p>

<p align="center">
    <a href="https://packagist.org/packages/hashtagcms/create-app"><img src="https://img.shields.io/packagist/v/hashtagcms/create-app.svg?style=flat-square" alt="Latest Version on Packagist"></a>
    <a href="https://packagist.org/packages/hashtagcms/create-app"><img src="https://img.shields.io/packagist/dt/hashtagcms/create-app.svg?style=flat-square" alt="Total Downloads"></a>
    <a href="https://packagist.org/packages/hashtagcms/create-app"><img src="https://img.shields.io/packagist/l/hashtagcms/create-app.svg?style=flat-square" alt="License"></a>
</p>

# HashtagCMS Starter Kit

Welcome to the **Official HashtagCMS Starter Kit**. This boilerplate provides a production-ready application structure pre-configured with **Laravel 13** and **HashtagCMS 3.x**, allowing you to launch powerful, headless-capable Content Management Systems in seconds.

## 🚀 About HashtagCMS

HashtagCMS is an enterprise-ready, API-first content management platform built on Laravel. It supports headless, bundled, and hybrid architectures, allowing organizations to manage multiple sites, platforms, and languages from a single centralized admin panel. Designed for scalability, performance, and long-term flexibility, HashtagCMS gives engineering teams full architectural control while enabling business teams to move faster with confidence.

## ✨ Key Features

-   **Multi-Tenancy**: Manage multiple sites, domains, and platforms from a single admin panel.
-   **Headless Ready**: Robust API for consuming content on React, Vue, Mobile, or any other consumer.
-   **Everything is a Module**: Drag-and-drop module placement for any part of the page.
-   **Smart Queries**: Fetch data from SQL using JSON configuration (no code needed).
-   **Extensible Admin**: Flexible view resolution supporting custom packages and theme overrides.
-   **Advanced Features**: MongoDB support, SSO, and Figma Integration (coming soon).

### Modular Admin Architecture

HashtagCMS supports a fully modular admin panel. You can easily integrate external packages (like HashtagCMS Extended) or override standard CRUD views directly from the database configuration, enabling seamless upgrades and customization.

### HashtagCMS Ecosystem

HashtagCMS is part of a broader ecosystem of packages published under the `@hashtagcms` npm namespace and the `hashtagcms` Packagist vendor, covering the core CMS, admin UI kit, web SDK, and more.

## 🆕 What's New in v3.0.0

-   **Tailwind CSS**: Entire frontend migrated to Tailwind CSS with a new default theme.
-   **Vue 3 Composition API**: Admin UI kit fully rewritten using Vue 3 Composition API.
-   **Re-engineered Module Creator**: Redesigned for better modularity and speed.
-   **Module Type CMS Module**: New dynamic type management module.
-   **SiteClonerService**: New robust service for site and language cloning.
-   **Pipeline-based Resolver**: New system for resolving Site, Lang, Platform, and Route.
-   **Queue-Driven Tasks**: All long-running tasks are now handled via Laravel Jobs.
-   **Enhanced RBAC**: Improved CMS Policies with site-wise permissions and audit logging.
-   **Advanced Service Discovery**: Improved Custom Module Loader.

## 🛠 Installation

### 🐳 Via Docker (Recommended)

The easiest way to get started is using Docker. Ensure you have Docker and Docker Compose installed.

For detailed Docker instructions and troubleshooting, see the [DOCKER-README.md](DOCKER-README.md).

```bash
git clone https://github.com/hashtagcms/create-app.git my-awesome-site
cd my-awesome-site
./cms build
```

Once the containers are running, visit `http://localhost:8081/install` to complete the setup.

### 📦 Via Composer

#### Option A — Starter Kit (Recommended)

```bash
composer create-project hashtagcms/create-app my-awesome-site
cd my-awesome-site
php artisan cms:install
```

#### Option B — Fresh Laravel Project

```bash
composer create-project laravel/laravel my-awesome-site
cd my-awesome-site
composer require hashtagcms/hashtagcms
php artisan cms:install
```

### 2. Database Setup

By default, this starter kit is configured to use **SQLite** for instant setup (zero configuration).

**Copy .env.example to .env**
```bash
cp .env.example .env
```

**To use MySQL/PostgreSQL:**
1.  Open the `.env` file in your new project.
2.  Update the database credentials:
    ```dotenv
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=your_database
    DB_USERNAME=root
    DB_PASSWORD=
    ```

3.  Open `app/Models/User.php` and replace:
    ```php
    use Illuminate\Foundation\Auth\User as Authenticatable;
    ```
    with:
    ```php
    use HashtagCms\User as Authenticatable;
    ```

4.  Run the installer to populate the database:
    ```bash
    php artisan cms:install
    ```

### 3. Configure & Access

Open your browser and navigate to:

```
http://{APP_URL}/install
```

After installation, visit:

-   **Frontend**: `http://your-domain.com`
-   **Admin Panel**: `http://your-domain.com/admin`

*Login details will be provided during the `cms:install` process.*

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory of the core repository:

-   [**Start Here: Documentation Index**](https://github.com/hashtagcms/hashtagcms/blob/master/docs/00-index.md)
-   [Installation Guide](https://github.com/hashtagcms/hashtagcms/blob/master/docs/02-installation.md)
-   [Quick Start](https://github.com/hashtagcms/hashtagcms/blob/master/docs/03-quick-start.md)
-   [API Reference](https://github.com/hashtagcms/hashtagcms/blob/master/docs/13-api-headless.md)
-   [Feature List](https://github.com/hashtagcms/hashtagcms/blob/master/docs/features.md)

## 🧪 Testing

This kit comes with standard Laravel tests. To run them:

```bash
php artisan test
```

## 📋 Changelog

Full version history is maintained in the core repository:

[**📋 View Changelog**](https://github.com/hashtagcms/hashtagcms/blob/master/changelog.md)

**Recent highlights:**
- **v3.0.0** — Tailwind CSS frontend, Vue 3 Composition API admin, Queue-driven tasks, enhanced RBAC
- **v2.0.5** — FormHelper XSS prevention, FrontendHelper stability improvements
- **v2.0.4** — Intelligent admin view resolution, routing and module parsing enhancements
- **v2.0.3** — Configurable rate limiting on critical endpoints
- **v2.0.0** — Event-driven architecture, removed `laravel/ui`, all large tasks are queue/event-driven

## 🤝 Contributing

Contributions are welcome! The contribution guide can be found in the [HashtagCMS Core Repository](https://github.com/hashtagcms/hashtagcms/blob/master/contributing.md).

## 📄 License

The HashtagCMS framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
