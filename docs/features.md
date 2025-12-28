# Panda Script - Kiến trúc Chức năng v2.3

> **Triết lý thiết kế**: Sắp xếp theo **Mục đích sử dụng**, không phải theo chức năng kỹ thuật

---

# 🎯 CẤU TRÚC WEB PANEL v3

## Sidebar (4 Nhóm Trụ cột)

```
🚀 DEPLOYMENT (Tài nguyên chính)
├── Websites          -> Create: Empty / CMS / App
├── Projects          -> Node.js, Python, Java
├── Docker            -> Containers
└── Databases         -> MariaDB

📂 MANAGEMENT (Quản lý & Vận hành)
├── File Manager      -> Browse, Edit, Upload
├── Backups           -> Local & Cloud
└── Cron Jobs         -> Scheduled tasks

🛠️ ENVIRONMENT (Cấu hình môi trường)
├── PHP Manager       -> Versions & Extensions
├── Nginx Config      -> Vhosts, Optimization
├── SSL Certificates  -> Let's Encrypt
└── App Store         -> Redis, Memcached, Tools

🛡️ INFRASTRUCTURE (Bảo mật & Hệ thống)
├── Security          -> Firewall, SSH, Fail2Ban
├── System Health     -> Stats, Logs, Processes
├── Web Terminal      -> Shell in browser
└── Settings          -> Users, 2FA, Panel Config
```

---

## Luồng "Create Website" (3 lựa chọn)

Khi nhấn **"Add Site"** trong Websites:

```
┌─────────────────────────────────────────────────┐
│         What would you like to create?          │
├─────────────────────────────────────────────────┤
│                                                 │
│  📄 Empty Site                                  │
│     Blank website, upload your own code         │
│                                                 │
│  🚀 CMS One-Click                               │
│     WordPress, Joomla, Drupal, WooCommerce...   │
│                                                 │
│  💻 App/Project                                 │
│     Node.js, Python, Java application           │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Smart Dashboard (Action-oriented)

Thay vì chỉ hiện charts, hiện **Quick Actions**:

```
┌─ Quick Actions ─────────────────────────────────┐
│                                                 │
│  [+ New Website]  [🔧 Fix Permissions]  [📋 Logs] │
│                                                 │
│  Recent Sites:                                  │
│  • example.com     [Manage] [SSL] [Files]       │
│  • myapp.dev       [Manage] [SSL] [Files]       │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Contextual SSL

SSL button ngay trong danh sách Websites:

```
┌─ Websites ──────────────────────────────────────┐
│ Domain            SSL        Actions            │
├─────────────────────────────────────────────────┤
│ example.com       🔒 Active  [Manage] [Files]   │
│ newsite.com       [Enable]   [Manage] [Files]   │
│                    ↑                            │
│            Click to install SSL instantly       │
└─────────────────────────────────────────────────┘
```

---

## Command Palette (Ctrl+K)

Gõ bất kỳ từ khóa nào:

| Gõ | Kết quả |
|----|---------|
| `wp` | Hiện các site WordPress |
| `log` | Mở xem logs |
| `ssl` | Quản lý SSL |
| `restart` | Restart services |
| `backup` | Tạo backup |

---

# 🖥️ CẤU TRÚC CLI v2.3

## Menu Chính (7 mục - Quy tắc ghi nhớ)

```
╔══════════════════════════════════════════════════════════════╗
║          🐼 Panda Script v2.3 - High Performance LEMP        ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  1. 🌐 Websites    → Create, Delete, CMS, Clone, WP-CLI      ║
║  2. 📦 Projects    → Node.js, Python, Java Manager           ║
║  3. 🗄️ Databases   → MariaDB, Sync, Slow Query               ║
║  4. ⚙️ Services    → PHP, Nginx, SSL, Docker, Redis          ║
║  5. 🛡️ Security    → Firewall, SSH, Guard, Permissions       ║
║  6. 🔧 System      → Backup, Monitor, Tools, Cleanup         ║
║  7. 🎛️ Panel       → v3 Web Panel, Update, Settings          ║
║                                                              ║
║  0. ❌ Exit                                                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Menu Con Chi tiết

### 1. 🌐 Websites
```
├── 1. Create Website
│   ├── Empty Site
│   ├── CMS One-Click (9 loại)
│   └── WordPress with WP-CLI
├── 2. Delete Website
├── 3. List Websites
├── 4. Clone Website
├── 5. WP-CLI Management
└── 0. Back
```

### 2. 📦 Projects
```
├── 1. Node.js Manager
│   ├── Create Project
│   ├── Clone from GitHub
│   ├── PM2 Dashboard
│   └── Start/Stop/Restart
├── 2. Python Manager
│   ├── Create Project (Flask/Django/FastAPI)
│   ├── Clone from GitHub
│   └── Virtualenv Management
├── 3. Java Manager
│   ├── Create Spring Boot
│   └── Maven/Gradle Build
├── 4. Deployment Workflow
│   ├── Setup Auto-Deploy
│   ├── GitHub Webhook
│   └── View Deploy Logs
└── 0. Back
```

### 3. 🗄️ Databases
```
├── 1. Create Database
├── 2. Delete Database
├── 3. List Databases
├── 4. Create User
├── 5. Sync Database
├── 6. Slow Query Analysis
└── 0. Back
```

### 4. ⚙️ Services
```
├── 1. PHP Manager
│   ├── Install Version
│   ├── Switch Version
│   ├── Extensions
│   └── php.ini Config
├── 2. Nginx Manager
│   ├── Test Config
│   ├── Reload
│   └── Optimize
├── 3. SSL Manager
│   ├── Obtain Certificate
│   ├── Renew All
│   └── Check Expiry
├── 4. Docker Manager
├── 5. Redis/Memcached
└── 0. Back
```

### 5. 🛡️ Security
```
├── 1. Firewall (UFW)
├── 2. Change SSH Port
├── 3. Fail2Ban Setup
├── 4. Fix Permissions
├── 5. Security Hardening
└── 0. Back
```

### 6. 🔧 System
```
├── 1. Backup Manager
│   ├── Create Backup
│   ├── Restore Backup
│   ├── Cloud Backup (Rclone)
│   └── Schedule Backup
├── 2. System Monitor
│   ├── Resource Usage
│   ├── View Logs
│   └── Process Manager
├── 3. Performance
│   ├── Swap Management
│   ├── OPCache Config
│   └── System Optimize
├── 4. System Cleanup
├── 5. Cron Jobs
└── 0. Back
```

### 7. 🎛️ Panel
```
├── 1. Open Web Panel (v3)
├── 2. Panel Settings
├── 3. Change Panel Port
├── 4. Enable Panel SSL
├── 5. Update Panda Script
└── 0. Back
```

---

# 📊 MAPPING: CLI ↔ WEB PANEL

| CLI Menu | Web Panel Section |
|----------|-------------------|
| 1. Websites | 🚀 DEPLOYMENT → Websites |
| 2. Projects | 🚀 DEPLOYMENT → Projects |
| 3. Databases | 🚀 DEPLOYMENT → Databases |
| 4. Services → PHP | 🛠️ ENVIRONMENT → PHP Manager |
| 4. Services → Nginx | 🛠️ ENVIRONMENT → Nginx Config |
| 4. Services → SSL | 🛠️ ENVIRONMENT → SSL Certificates |
| 4. Services → Docker | 🚀 DEPLOYMENT → Docker |
| 5. Security | 🛡️ INFRASTRUCTURE → Security |
| 6. System → Backup | � MANAGEMENT → Backups |
| 6. System → Monitor | 🛡️ INFRASTRUCTURE → System Health |
| 7. Panel | 🛡️ INFRASTRUCTURE → Settings |

---

# 🎨 UX IMPROVEMENTS

## 1. Global Search (Ctrl+K) ✅
- Đã implement trong `CommandPalette.vue`
- Tìm kiếm pages, actions, commands

## 2. Smart Dashboard ✅
- Quick Actions: New Website, Fix Permissions, View Logs
- Recent Sites với nút Manage/SSL/Files

## 3. Contextual SSL ✅
- Nút Enable SSL ngay trong table Websites
- One-click SSL installation

## 4. Skeleton Loading ✅
- Thay spinner bằng skeleton screens
- Perceived performance tốt hơn

## 5. Optimistic UI ✅
- Actions update ngay lập tức
- Revert nếu API fail

## 6. Keyboard First ✅
- Ctrl+K: Command Palette
- Ctrl+T: Toggle Theme
- Arrow keys: Navigate
- Enter: Select

---

# 📁 FILES CẦN UPDATE

## Web Panel (v3)

### Sidebar Restructure
- `MainLayout.vue` - Grouped sidebar với collapsible sections

### Website Flow
- `Websites.vue` - Add "Create Type" modal
- Gộp CMS vào luồng tạo website

### Dashboard
- `Dashboard.vue` - Quick Actions + Recent Sites

## CLI

### Main Menu
- `menu/main.sh` - 7 mục thay vì 14

### Submenu Restructure
- Gộp các menu nhỏ vào 7 nhóm lớn

---

# 🏆 SO SÁNH VỚI CLOUDPANEL/AAPANEL

| Feature | CloudPanel | aaPanel | Panda v3 |
|---------|------------|---------|----------|
| Grouped Sidebar | ✅ | ❌ | ✅ |
| Command Palette | ❌ | ❌ | ✅ |
| Contextual SSL | ❌ | ✅ | ✅ |
| Skeleton Loading | ❌ | ❌ | ✅ |
| Optimistic UI | ❌ | ❌ | ✅ |
| Keyboard Shortcuts | ❌ | ❌ | ✅ |
| CMS in Website Flow | ❌ | ✅ | ✅ |
| Project Managers | ❌ | ❌ | ✅ |
| CLI + Web Panel | ❌ | ❌ | ✅ |