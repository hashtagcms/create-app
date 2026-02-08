
<p align="center">
    <a href="https://www.hashtagcms.org" target="_blank">
        <img src="https://www.hashtagcms.org/img/logo.png" width="300" alt="HashtagCMS Logo">
    </a>
</p>

<p align="center">
    <a href="https://packagist.org/packages/hashtagcms/create-app"><img src="https://img.shields.io/packagist/v/hashtagcms/create-app.svg?style=flat-square" alt="Latest Version on Packagist"></a>
    <a href="https://packagist.org/packages/hashtagcms/create-app"><img src="https://img.shields.io/packagist/dt/hashtagcms/create-app.svg?style=flat-square" alt="Total Downloads"></a>
    <a href="https://packagist.org/packages/hashtagcms/create-app"><img src="https://img.shields.io/packagist/l/hashtagcms/create-app.svg?style=flat-square" alt="License"></a>
</p>

# HashtagCMS Starter Kit

Welcome to the **Official HashtagCMS Starter Kit**. This boilerplate provides a production-ready application structure pre-configured with **Laravel 12** and **HashtagCMS 2.x**, allowing you to launch powerful, headless-capable Content Management Systems in seconds.

## 🚀 About HashtagCMS

HashtagCMS is a headless-ready, API-centric Content Management System built on Laravel. It decouples the "Frontend/Headless" logic from the "Backend/Admin" logic, empowering developers to:

-   **Headless First**: robust API support for React, Vue, Mobile apps, or any other consumer.
-   **Multi-Tenancy**: Manage multiple sites, domains, and platforms from a single admin panel.
-   **Module-Based Architecture**: Drag-and-drop module placement for dynamic layouts.
-   **Smart Queries**: Fetch data via JSON configuration (Zero Code required for standard data fetching).
-   **Scale Ready**: Supports MongoDB, SSO (Extended), and high-traffic caching strategies.

## ✨ Features V2.0

-   **Event-Driven Architecture**: Core actions like site copying and publishing act on events.
-   **Modern Stack**: Built for Laravel 12.x and PHP 8.2+.
-   **Frontend Independence**: Removed `laravel/ui` dependency; pure JS/Frontend agnostic.
-   **Improved Admin**: Complete refactor of `AdminCrud` for smoother day-to-day operations.
-   **NPM Ecosystem**: All JS components are published under `@hashtagcms` namespace.

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

You can create a new project via Composer. This will assume you have PHP and Composer installed.

#### 1. Create Project
Run the following command in your terminal:

```bash
composer create-project hashtagcms/create-app mysite
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
3.  Run the installer to populate the database:
    ```bash
    php artisan cms:install
    ```

### 3. Access the Application

-   **Frontend**: `http://your-domain.test` (or `http://localhost:8000`)
-   **Admin Panel**: `http://your-domain.test/admin` (or `http://localhost:8000/admin`)

*Login details will be provided during the `cms:install` process.*

## 📚 Documentation

Detailed documentation for developers and content managers is available at:

[**📖 Official HashtagCMS Documentation**](https://github.com/hashtagcms/hashtagcms/blob/master/docs/00-index.md)

## 🧪 Testing

This kit comes with standard Laravel tests. To run them:

```bash
php artisan test
```

## 🤝 Contributing

Thank you for considering contributing to the HashtagCMS ecosystem! The contribution guide can be found in the [HashtagCMS Core Repository](https://github.com/hashtagcms/hashtagcms).

## 📄 License

The HashtagCMS framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
