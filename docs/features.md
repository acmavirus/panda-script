# Panda Script - Tổng hợp Chức năng v2.3

## Tổng quan

Panda Script là bộ công cụ quản lý server Linux toàn diện:
- **CLI (v2.3)**: Bash scripts chạy trực tiếp trên terminal
- **Web Panel (v3)**: Giao diện web với Go backend + Vue.js frontend

---

# � CÁC NHÓM CHỨC NĂNG

---

## 🌐 NHÓM 1: WEB & APPLICATIONS

> **Mục đích**: Quản lý toàn bộ web hosting - từ tạo website, cấu hình Nginx, SSL, đến triển khai ứng dụng Node.js/Python/Java

### 1.1 Website Management

| CLI Module | Chức năng |
|------------|-----------|
| `modules/website/create.sh` | Tạo website mới |
| `modules/website/clone.sh` | Clone website |
| `modules/website/wordpress.sh` | Cài WordPress |
| `modules/website/wp_cli.sh` | Quản lý WP-CLI |
| `modules/website/cms_installer.sh` | One-Click CMS (9 loại) |

**CMS được hỗ trợ**: WordPress, WooCommerce, Joomla, Drupal, PrestaShop, OpenCart, MediaWiki, phpBB, phpMyAdmin

### 1.2 Nginx Configuration

| CLI Module | Chức năng |
|------------|-----------|
| `modules/nginx/install.sh` | Cài đặt Nginx |
| `modules/nginx/vhost.sh` | Virtual hosts |
| `modules/nginx/optimize.sh` | Tối ưu performance |
| `modules/nginx/logs.sh` | Phân tích logs |

### 1.3 SSL/HTTPS

| CLI Module | Chức năng |
|------------|-----------|
| `modules/ssl/certbot.sh` | Let's Encrypt certificates |

**Tính năng**: Obtain, Renew, Auto-renew, Revoke

### 1.4 Project Managers (Node.js, Python, Java)

| CLI Module | Chức năng |
|------------|-----------|
| `modules/project/nodejs.sh` | Node.js + PM2 cluster |
| `modules/project/python.sh` | Python + Virtualenv + Gunicorn/Uvicorn |
| `modules/project/java.sh` | Java + Spring Boot + Maven |
| `modules/website/nodejs.sh` | Node.js websites |

**Framework hỗ trợ**:
- Node.js: Express, NestJS, Next.js, Nuxt.js
- Python: Flask, Django, FastAPI
- Java: Spring Boot

### 1.5 Deployment

| CLI Module | Chức năng |
|------------|-----------|
| `modules/website/deploy.sh` | Simple deployment |
| `modules/website/webhook.sh` | Webhook setup |
| `modules/deploy/workflow.sh` | GitHub auto-deploy |

### Web Panel Components

| Component | Chức năng |
|-----------|-----------|
| `Websites.vue` | CRUD websites |
| `CMSInstaller.vue` | Visual CMS installer |
| `Projects.vue` | Node.js/Python/Java manager |
| `SSL.vue` | SSL certificates |

### API Routes Summary

```
# Websites
GET/POST/DELETE /api/websites/

# CMS
GET  /api/cms/
POST /api/cms/install

# Nginx
GET/POST/DELETE /api/nginx/vhosts/
POST /api/nginx/ssl/:domain
POST /api/nginx/reload

# SSL
GET  /api/ssl/
POST /api/ssl/obtain
POST /api/ssl/renew/:domain

# Projects
GET/POST /api/nodejs/pm2
GET/POST/DELETE /api/python/projects
GET/POST /api/java/projects
POST /api/clone

# Deployment
GET/POST/DELETE /api/deploy/
POST /api/deploy/:name/trigger
```

---

## � NHÓM 2: DATA MANAGEMENT

> **Mục đích**: Quản lý databases, backup/restore, file manager

### 2.1 Database (MariaDB)

| CLI Module | Chức năng |
|------------|-----------|
| `modules/mariadb/install.sh` | Cài đặt MariaDB |
| `modules/mariadb/slow_query.sh` | Phân tích slow queries |
| `modules/mariadb/sync.sh` | Đồng bộ database |

### 2.2 Backup & Restore

| CLI Module | Chức năng |
|------------|-----------|
| `modules/backup/local.sh` | Local backup |
| `modules/backup/restore.sh` | Restore backup |
| `modules/cloud/rclone.sh` | Cloud backup (S3, GDrive...) |
| `modules/cloud/gdrive.sh` | Google Drive sync |

### 2.3 File Manager

**Web Panel Only** - Quản lý files qua browser

### Web Panel Components

| Component | Chức năng |
|-----------|-----------|
| `Databases.vue` | CRUD databases, users |
| `Backup.vue` | Backup/restore |
| `FileManager.vue` | File browser, editor |

### API Routes Summary

```
# Database
GET/POST/DELETE /api/databases/
POST /api/databases/query
POST /api/databases/:name/backup

# Backup
GET  /api/backup/
POST /api/backup/website/:domain
POST /api/backup/database/:name
POST /api/backup/full
POST /api/rclone/sync

# Files
GET  /api/files/list
GET  /api/files/read
POST /api/files/write
POST /api/files/upload
POST /api/files/compress
```

---

## �️ NHÓM 3: SECURITY & ACCESS

> **Mục đích**: Bảo mật server, quản lý users và quyền truy cập

### 3.1 Firewall & SSH

| CLI Module | Chức năng |
|------------|-----------|
| `modules/security/guard.sh` | Fail2Ban, hardening |
| `modules/security/ssh_port.sh` | Đổi SSH port |

### 3.2 User Management

**Web Panel** - Multi-user với roles và 2FA

### Web Panel Components

| Component | Chức năng |
|-----------|-----------|
| `Security.vue` | Firewall rules, IP whitelist |
| `Users.vue` | Multi-user management |
| `Login.vue` | Authentication |

### API Routes Summary

```
# Firewall
GET  /api/security/firewall
POST /api/security/firewall/enable
POST /api/security/whitelist
POST /api/security/blacklist
PUT  /api/security/ssh-port

# Auth & Users
POST /api/auth/login
GET/POST/DELETE /api/users/
POST /api/2fa/setup
POST /api/2fa/verify
GET  /api/whitelist/
```

---

## � NHÓM 4: SYSTEM & MONITORING

> **Mục đích**: Giám sát, tối ưu hệ thống

### 4.1 System Management

| CLI Module | Chức năng |
|------------|-----------|
| `modules/system/clean.sh` | Dọn dẹp hệ thống |
| `modules/system/cron.sh` | Quản lý cron jobs |
| `modules/system/optimize.sh` | Tối ưu hệ thống |
| `modules/system/permissions.sh` | Fix permissions |
| `modules/system/swap.sh` | Quản lý swap |

### 4.2 PHP Management

| CLI Module | Chức năng |
|------------|-----------|
| `modules/php/install.sh` | Multi PHP versions |
| `modules/php/switch.sh` | Switch version |
| `modules/php/extensions.sh` | Extensions manager |
| `modules/performance/opcache.sh` | OPCache config |

### 4.3 Services & Processes

**Web Panel** - Quản lý systemd services, kill processes

### Web Panel Components

| Component | Chức năng |
|-----------|-----------|
| `Dashboard.vue` | System stats, charts |
| `Services.vue` | Service manager |
| `Processes.vue` | Process manager |
| `PHP.vue` | PHP versions, extensions |
| `HealthCheck.vue` | Health check |
| `Terminal.vue` | Web terminal |

### API Routes Summary

```
# System
GET  /api/system/stats
GET  /api/health/check
POST /api/system/update

# Services
GET  /api/services/
POST /api/services/:name/:action

# Processes
GET  /api/processes/
DELETE /api/processes/:pid

# PHP
GET  /api/php/versions
POST /api/php/install
POST /api/php/switch
GET  /api/php/extensions
POST /api/php/extensions/install
```

---

## � NHÓM 5: DOCKER & APPS

> **Mục đích**: Quản lý containers và cài đặt ứng dụng

### 5.1 Docker

| CLI Module | Chức năng |
|------------|-----------|
| `modules/docker/manage.sh` | Docker management |

### 5.2 App Store & Dev Tools

**Web Panel** - Cài đặt tools như Redis, Memcached, ClamAV...

### Web Panel Components

| Component | Chức năng |
|-----------|-----------|
| `Docker.vue` | Container manager |
| `Tools.vue` | Dev tools installer |
| `AppStore.vue` | App marketplace |

### API Routes Summary

```
# Docker
GET  /api/docker/containers
POST /api/docker/containers/:id/:action

# Apps
GET  /api/apps/
POST /api/apps/:slug/install
POST /api/apps/:slug/uninstall

# Cache & Tools
POST /api/cache/redis/install
POST /api/cache/memcached/install
POST /api/scan/clamav/install
GET  /api/tools/status
```

---

# � TỔNG KẾT

## Thống kê

| Nhóm | CLI Modules | Vue Components | Mô tả |
|------|-------------|----------------|-------|
| Web & Apps | 18 | 4 | Websites, Nginx, SSL, Projects, Deploy |
| Data | 7 | 3 | Database, Backup, Files |
| Security | 3 | 3 | Firewall, SSH, Users, 2FA |
| System | 9 | 6 | Monitoring, PHP, Services, Terminal |
| Docker & Apps | 1 | 3 | Containers, Dev Tools |
| **TOTAL** | **38** | **19** | |

## Menu Structure (CLI)

```
🐼 Panda Script v2.3
├── 1. 🌐 Website Management
│   ├── Create Website
│   ├── Delete Website
│   ├── List Websites
│   ├── WordPress Install
│   ├── Node.js Website
│   ├── Clone Website
│   ├── WP-CLI Management
│   └── One-Click CMS (NEW!)
│
├── 2. 🗄️ Database Management
├── 3. 🔐 SSL Management
├── 4. 🐘 PHP Management
├── 5. 🔧 Nginx Management
├── 6. 🐳 Docker Management
├── 7. 💾 Backup & Restore
├── 8. 🛡️ Security
├── 9. 📊 System Monitoring
├── 10. 🚀 Performance
├── 11. ⚙️ System Tools
├── 12. ☁️ Cloud Backup
├── 13. 👨‍💻 Developer Tools
│   ├── Simple Deployment
│   ├── Setup Webhook
│   └── Deployment Workflow (NEW!)
│
└── 14. 📦 Project Manager (NEW!)
    ├── Node.js Projects
    ├── Python Projects
    └── Java Projects
```

## Sidebar Structure (Web Panel v3)

```
🐼 Panda Panel v3
├── Dashboard
├── Sites (Websites)
├── Databases
├── Files
├── Terminal
├── ─────────────
├── Services
├── PHP
├── SSL
├── Security
├── Backup
├── ─────────────
├── Projects (NEW!)
├── CMS Install (NEW!)
├── Apps
├── Tools
├── ─────────────
├── Health
├── Users
└── Settings
```

---

## Kết luận

Sau khi gộp, Panda Script có **5 nhóm chức năng chính**:

1. **🌐 Web & Applications** - Tất cả về web hosting
2. **💾 Data Management** - Database, backup, files
3. **🛡️ Security & Access** - Bảo mật và users
4. **📊 System & Monitoring** - Hệ thống và PHP
5. **🐳 Docker & Apps** - Containers và tools