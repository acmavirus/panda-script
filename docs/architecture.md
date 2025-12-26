# Kiến trúc hệ thống Panda Script v2.0

## 📋 Tổng quan

Panda Script v2.0 được thiết kế với kiến trúc **event-driven**, **modular** và **high-performance**, tập trung vào:
- 🚀 **Hiệu suất cao**: Async processing, caching, optimized configs
- 🔒 **Bảo mật đa lớp**: Defense in depth, real-time threat detection
- 📢 **Cảnh báo thông minh**: Telegram alerts cho DDoS, RAM, System hang
- 📊 **Monitoring proactive**: Phát hiện sớm các vấn đề

---

## 🏗️ Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          🐼 Panda Script v2.0                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        🔔 ALERT SYSTEM                                  │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │ │
│  │  │   Telegram   │ │    Email     │ │   Webhook    │ │   Discord    │   │ │
│  │  │    Bot API   │ │    SMTP      │ │   Custom     │ │   Webhook    │   │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      ▲                                       │
│                                      │                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     🛡️ SECURITY & MONITORING LAYER                     │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐   │ │
│  │  │   DDoS     │ │   RAM      │ │  System    │ │   Intrusion        │   │ │
│  │  │  Detector  │ │  Monitor   │ │  Health    │ │   Detection        │   │ │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      ▲                                       │
│                                      │                                       │
│  ┌──────────────┐   ┌──────────────┐ │ ┌──────────────┐                     │
│  │   CLI Menu   │   │  Installer   │ │ │   Updater    │                     │
│  │   (panda)    │   │   (install)  │ │ │   (update)   │                     │
│  └──────┬───────┘   └──────┬───────┘ │ └──────┬───────┘                     │
│         │                  │         │        │                              │
│         ▼                  ▼         │        ▼                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         CORE ENGINE                                  │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐   │    │
│  │  │ Common  │ │   OS    │ │ Network │ │Security │ │  Performance│   │    │
│  │  │Functions│ │ Detect  │ │  Utils  │ │  Core   │ │   Tuner     │   │    │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│         ┌────────────────────┼────────────────────┐                         │
│         ▼                    ▼                    ▼                         │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                │
│  │    Modules     │  │    Modules     │  │    Modules     │                │
│  │   (Website)    │  │  (Database)    │  │  (Security)    │                │
│  └────────────────┘  └────────────────┘  └────────────────┘                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Cấu trúc Source Code tối ưu

```
panda-script/
│
├── install                          # Entry point - Main installer
├── panda                            # CLI management tool
├── update                           # Script updater
│
├── core/                            # 🔥 Core Engine (Performance Critical)
│   ├── init.sh                     # Bootstrap & initialization
│   ├── common.sh                   # Colors, logging, prompts
│   ├── os_detect.sh                # OS detection & validation
│   ├── package.sh                  # Package manager abstraction
│   ├── service.sh                  # Service management
│   ├── network.sh                  # Network utilities
│   └── utils.sh                    # General utilities
│
├── security/                        # 🛡️ Security Layer
│   ├── firewall/
│   │   ├── firewall.sh            # Firewall management
│   │   ├── iptables_rules.sh      # IPTables advanced rules
│   │   ├── rate_limit.sh          # Connection rate limiting
│   │   └── geo_block.sh           # Country-based blocking
│   │
│   ├── ddos/
│   │   ├── detector.sh            # DDoS detection engine
│   │   ├── mitigation.sh          # Auto-mitigation actions
│   │   ├── blacklist.sh           # IP blacklist management
│   │   └── whitelist.sh           # Trusted IPs
│   │
│   ├── intrusion/
│   │   ├── fail2ban.sh            # fail2ban management
│   │   ├── aide.sh                # File integrity
│   │   ├── rootkit_scan.sh        # Rootkit detection
│   │   └── malware_scan.sh        # Malware scanning
│   │
│   ├── hardening/
│   │   ├── ssh_harden.sh          # SSH security
│   │   ├── kernel_harden.sh       # Kernel parameters
│   │   ├── permission_audit.sh    # Permission checker
│   │   └── ssl_audit.sh           # SSL/TLS audit
│   │
│   └── audit/
│       ├── security_scan.sh       # Full security scan
│       ├── vulnerability.sh       # CVE checking
│       └── report.sh              # Security reports
│
├── monitoring/                      # 📊 Monitoring & Alerting
│   ├── collectors/
│   │   ├── cpu_collector.sh       # CPU metrics
│   │   ├── ram_collector.sh       # RAM metrics
│   │   ├── disk_collector.sh      # Disk metrics
│   │   ├── network_collector.sh   # Network metrics
│   │   └── service_collector.sh   # Service health
│   │
│   ├── analyzers/
│   │   ├── threshold_analyzer.sh  # Threshold checking
│   │   ├── trend_analyzer.sh      # Trend detection
│   │   ├── anomaly_detector.sh    # Anomaly detection
│   │   └── correlation.sh         # Event correlation
│   │
│   ├── alerts/
│   │   ├── alert_manager.sh       # Alert orchestration
│   │   ├── telegram.sh            # Telegram notifications
│   │   ├── email.sh               # Email notifications
│   │   ├── webhook.sh             # Webhook calls
│   │   └── discord.sh             # Discord notifications
│   │
│   └── daemon/
│       ├── monitor_daemon.sh      # Background monitor
│       ├── health_check.sh        # System health
│       └── watchdog.sh            # Process watchdog
│
├── performance/                     # 🚀 Performance Optimization
│   ├── tuning/
│   │   ├── auto_tune.sh           # Auto performance tuning
│   │   ├── nginx_tune.sh          # Nginx optimization
│   │   ├── php_tune.sh            # PHP optimization
│   │   ├── mysql_tune.sh          # MariaDB optimization
│   │   └── kernel_tune.sh         # Kernel parameters
│   │
│   ├── cache/
│   │   ├── opcache.sh             # PHP OPcache
│   │   ├── redis.sh               # Redis cache
│   │   ├── memcached.sh           # Memcached
│   │   └── nginx_cache.sh         # Nginx FastCGI cache
│   │
│   └── benchmark/
│       ├── stress_test.sh         # Load testing
│       ├── benchmark.sh           # Performance benchmark
│       └── report.sh              # Performance reports
│
├── modules/                         # 📦 Feature Modules
│   ├── nginx/
│   │   ├── install.sh
│   │   ├── config.sh
│   │   ├── vhost.sh
│   │   ├── security.sh            # Nginx security
│   │   └── templates/
│   │       ├── nginx.conf.tpl
│   │       ├── vhost.conf.tpl
│   │       ├── security.conf.tpl
│   │       └── cache.conf.tpl
│   │
│   ├── mariadb/
│   │   ├── install.sh
│   │   ├── config.sh
│   │   ├── user.sh
│   │   ├── backup.sh
│   │   └── templates/
│   │       └── my.cnf.tpl
│   │
│   ├── php/
│   │   ├── install.sh
│   │   ├── config.sh
│   │   ├── extensions.sh
│   │   └── templates/
│   │       ├── php.ini.tpl
│   │       └── pool.conf.tpl
│   │
│   ├── website/
│   │   ├── create.sh
│   │   ├── delete.sh
│   │   ├── list.sh
│   │   ├── wordpress.sh
│   │   └── laravel.sh
│   │
│   ├── ssl/
│   │   ├── letsencrypt.sh
│   │   ├── self_signed.sh
│   │   └── renew.sh
│   │
│   └── backup/
│       ├── local.sh
│       ├── remote.sh
│       ├── gdrive.sh
│       ├── s3.sh
│       └── restore.sh
│
├── menu/                            # 🖥️ Menu System
│   ├── main.sh
│   ├── website.sh
│   ├── database.sh
│   ├── ssl.sh
│   ├── backup.sh
│   ├── php.sh
│   ├── nginx.sh
│   ├── security.sh
│   ├── monitoring.sh
│   └── system.sh
│
├── config/                          # ⚙️ Configuration
│   ├── panda.conf                  # Main config
│   ├── alerts.conf                 # Alert settings
│   ├── thresholds.conf             # Monitoring thresholds
│   └── security.conf               # Security settings
│
├── data/                            # 💾 Runtime Data
│   ├── db/
│   │   └── panda.db                # SQLite database
│   ├── cache/
│   ├── logs/
│   └── tmp/
│
├── docs/                            # 📚 Documentation
│
└── tests/                           # 🧪 Tests
    ├── unit/
    ├── integration/
    └── security/
```

---

## 🔔 Hệ thống Cảnh báo Telegram

### Kiến trúc Alert System

```
┌─────────────────────────────────────────────────────────────────┐
│                      ALERT SYSTEM FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │   Monitor   │────▶│  Analyzer   │────▶│   Alert     │       │
│  │   Daemon    │     │   Engine    │     │   Manager   │       │
│  └─────────────┘     └─────────────┘     └──────┬──────┘       │
│                                                  │               │
│         ┌────────────────┬───────────────┬──────┴────┐         │
│         ▼                ▼               ▼           ▼         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐ ┌────────┐    │
│  │  Telegram  │  │   Email    │  │  Discord   │ │Webhook │    │
│  │    Bot     │  │   SMTP     │  │   Webhook  │ │ Custom │    │
│  └────────────┘  └────────────┘  └────────────┘ └────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Cấu hình Telegram (`config/alerts.conf`)

```ini
[telegram]
enabled = true
bot_token = "YOUR_BOT_TOKEN"
chat_id = "-100123456789"
# Có thể thêm nhiều chat_id
chat_ids = "-100123456789,-100987654321"

# Alert levels
alert_critical = true
alert_warning = true
alert_info = false

# Rate limiting (tránh spam)
rate_limit = 60              # seconds between same alerts
daily_limit = 100            # max alerts per day

# Templates
template_dir = "/opt/panda/templates/alerts"
```

### Các loại cảnh báo

| Alert Type | Trigger | Severity | Action |
|------------|---------|----------|--------|
| DDoS Attack | >1000 conn/IP/min | 🔴 Critical | Auto-block IP + Alert |
| RAM Full | >90% usage | 🔴 Critical | Kill process + Alert |
| RAM High | >80% usage | 🟡 Warning | Alert only |
| System Hang | No response 30s | 🔴 Critical | Force restart + Alert |
| CPU Overload | >95% for 5min | 🟡 Warning | Alert + log |
| Disk Full | >90% usage | 🔴 Critical | Alert + cleanup |
| Service Down | nginx/php/mysql | 🔴 Critical | Auto-restart + Alert |
| SSH Brute Force | >10 failed/min | 🟡 Warning | Block IP + Alert |
| SSL Expiring | <7 days | 🟡 Warning | Alert only |

---

## 🛡️ DDoS Detection & Mitigation

### Detection Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                    DDoS DETECTION ENGINE                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Data Collectors                        │    │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌─────────┐ │    │
│  │  │  Netstat  │ │  IPTables │ │  Nginx    │ │  SS     │ │    │
│  │  │  Monitor  │ │   Logs    │ │   Logs    │ │ Stats   │ │    │
│  │  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └────┬────┘ │    │
│  └────────┼─────────────┼─────────────┼────────────┼───────┘    │
│           └─────────────┴──────┬──────┴────────────┘            │
│                                ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Analysis Engine                        │    │
│  │                                                          │    │
│  │  • Connection Rate Analysis (conn/sec per IP)           │    │
│  │  • Request Pattern Analysis (same URL attacks)          │    │
│  │  • Geographic Anomaly (unusual country traffic)         │    │
│  │  • Protocol Anomaly (SYN flood, UDP flood)              │    │
│  │  • Bandwidth Anomaly (sudden spikes)                    │    │
│  │                                                          │    │
│  └───────────────────────────┬─────────────────────────────┘    │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Threat Classification                  │    │
│  │                                                          │    │
│  │  Level 1: Suspicious  → Monitor + Log                   │    │
│  │  Level 2: Likely      → Rate Limit + Alert              │    │
│  │  Level 3: Confirmed   → Block + Mitigate + Alert        │    │
│  │  Level 4: Severe      → Emergency Mode + Full Alert     │    │
│  │                                                          │    │
│  └───────────────────────────┬─────────────────────────────┘    │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Mitigation Actions                     │    │
│  │                                                          │    │
│  │  • IP Blacklist (auto + manual)                         │    │
│  │  • Rate Limiting (nginx + iptables)                     │    │
│  │  • Connection Limiting                                   │    │
│  │  • Geographic Blocking                                   │    │
│  │  • Cloudflare API (if configured)                       │    │
│  │  • Null Route (extreme cases)                           │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Thresholds (`config/thresholds.conf`)

```ini
[ddos]
# Connection thresholds per IP
conn_per_ip_warning = 100
conn_per_ip_critical = 300
conn_per_ip_block = 500

# Request rate thresholds
req_per_sec_warning = 50
req_per_sec_critical = 100
req_per_sec_block = 200

# Bandwidth thresholds (Mbps)
bandwidth_warning = 100
bandwidth_critical = 500

# SYN flood detection
syn_per_sec_warning = 100
syn_per_sec_critical = 500

# Block duration (seconds)
block_duration_level1 = 300      # 5 minutes
block_duration_level2 = 3600     # 1 hour
block_duration_level3 = 86400    # 24 hours
block_duration_level4 = 604800   # 7 days

[ram]
warning_percent = 80
critical_percent = 90
emergency_percent = 95

[cpu]
warning_percent = 80
critical_percent = 95
sustained_seconds = 300

[disk]
warning_percent = 80
critical_percent = 90

[system]
hang_timeout = 30
service_check_interval = 10
```

---

## 📊 Monitoring Daemon

### Daemon Architecture

```bash
# /opt/panda/monitoring/daemon/monitor_daemon.sh

┌─────────────────────────────────────────────────────────────────┐
│                     MONITOR DAEMON                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Main Loop (every 5 seconds)                                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  1. Collect Metrics                                       │  │
│  │     ├─ CPU usage                                          │  │
│  │     ├─ RAM usage                                          │  │
│  │     ├─ Disk usage                                         │  │
│  │     ├─ Network connections                                │  │
│  │     ├─ Service status                                     │  │
│  │     └─ Load average                                       │  │
│  │                                                            │  │
│  │  2. Analyze & Compare with Thresholds                     │  │
│  │                                                            │  │
│  │  3. Detect Anomalies                                      │  │
│  │     ├─ DDoS patterns                                      │  │
│  │     ├─ Resource spikes                                    │  │
│  │     └─ Service failures                                   │  │
│  │                                                            │  │
│  │  4. Take Actions                                          │  │
│  │     ├─ Auto-mitigation (if enabled)                       │  │
│  │     ├─ Send alerts                                        │  │
│  │     └─ Log events                                         │  │
│  │                                                            │  │
│  │  5. Update Metrics Database                               │  │
│  │                                                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Watchdog (separate thread)                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • Check if main daemon is responsive                     │  │
│  │  • Restart daemon if frozen                               │  │
│  │  • Send alert if daemon fails                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Systemd Service

```ini
# /etc/systemd/system/panda-monitor.service

[Unit]
Description=Panda Script Monitoring Daemon
After=network.target

[Service]
Type=simple
ExecStart=/opt/panda/monitoring/daemon/monitor_daemon.sh
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
StandardOutput=append:/opt/panda/data/logs/monitor.log
StandardError=append:/opt/panda/data/logs/monitor-error.log

# Resource limits
MemoryMax=128M
CPUQuota=10%

# Security
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/panda/data

[Install]
WantedBy=multi-user.target
```

---

## 🚀 Performance Optimization

### Auto-Tuning Based on RAM

```bash
# Tự động điều chỉnh cấu hình theo RAM

RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')

if [ "$RAM_TOTAL" -lt 1024 ]; then
    # 1GB RAM
    PHP_WORKERS=2
    NGINX_WORKERS=1
    MYSQL_BUFFER=128M
    OPCACHE_MEMORY=64
elif [ "$RAM_TOTAL" -lt 2048 ]; then
    # 2GB RAM
    PHP_WORKERS=4
    NGINX_WORKERS=2
    MYSQL_BUFFER=256M
    OPCACHE_MEMORY=128
elif [ "$RAM_TOTAL" -lt 4096 ]; then
    # 4GB RAM
    PHP_WORKERS=8
    NGINX_WORKERS=4
    MYSQL_BUFFER=512M
    OPCACHE_MEMORY=256
else
    # 4GB+ RAM
    PHP_WORKERS=16
    NGINX_WORKERS=auto
    MYSQL_BUFFER=1G
    OPCACHE_MEMORY=512
fi
```

### Kernel Tuning (`/etc/sysctl.d/99-panda.conf`)

```ini
# Network Performance
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# TCP Optimization
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_tw_reuse = 1

# DDoS Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# Memory
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

# File Descriptors
fs.file-max = 2097152
fs.nr_open = 2097152
```

---

## 🔒 Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: CDN/Proxy (Cloudflare)                                │
│  • DDoS mitigation at edge                                      │
│  • Bot protection                                               │
│  • WAF rules                                                    │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 2: Network Firewall (iptables/nftables)                  │
│  • Port filtering                                               │
│  • Rate limiting                                                │
│  • Geo-blocking                                                 │
│  • SYN flood protection                                         │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 3: Application Firewall (fail2ban + Nginx)               │
│  • Brute force protection                                       │
│  • Bad bot blocking                                             │
│  • Request filtering                                            │
│  • Security headers                                             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 4: System Security (Hardening)                           │
│  • SSH hardening                                                │
│  • File permissions                                             │
│  • User isolation                                               │
│  • AIDE integrity                                               │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Layer 5: Application Security                                   │
│  • PHP sandbox (disable_functions)                              │
│  • open_basedir                                                 │
│  • SQL injection prevention                                     │
│  • XSS protection                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📝 Telegram Alert Templates

### Critical Alert Template

```
🚨 *CRITICAL ALERT*

*Server:* {{hostname}}
*Time:* {{timestamp}}
*Type:* {{alert_type}}

━━━━━━━━━━━━━━━━━━━━
📊 *Details:*
{{details}}

⚡ *Auto Actions Taken:*
{{actions}}

🔗 *Quick Actions:*
/status - Check status
/unblock {{ip}} - Unblock IP
/restart {{service}} - Restart service
━━━━━━━━━━━━━━━━━━━━
```

### DDoS Alert Template

```
🔥 *DDoS ATTACK DETECTED*

*Server:* {{hostname}}
*Time:* {{timestamp}}
*Level:* {{level}} (1-4)

━━━━━━━━━━━━━━━━━━━━
📊 *Attack Info:*
• Type: {{attack_type}}
• Source IPs: {{ip_count}}
• Connections/sec: {{conn_rate}}
• Bandwidth: {{bandwidth}}

🎯 *Top Attackers:*
{{top_ips}}

⚡ *Mitigation:*
{{mitigation_status}}
━━━━━━━━━━━━━━━━━━━━
```

### RAM Alert Template

```
💾 *HIGH RAM USAGE*

*Server:* {{hostname}}
*Time:* {{timestamp}}

━━━━━━━━━━━━━━━━━━━━
📊 *Memory Status:*
• Used: {{ram_used}}GB / {{ram_total}}GB
• Usage: {{ram_percent}}%
• Swap: {{swap_used}}GB / {{swap_total}}GB

📋 *Top Processes:*
{{top_processes}}

⚡ *Actions:*
{{actions}}
━━━━━━━━━━━━━━━━━━━━
```

---

## 📊 Database Schema (SQLite)

```sql
-- Websites
CREATE TABLE websites (
    id INTEGER PRIMARY KEY,
    domain TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    document_root TEXT NOT NULL,
    php_version TEXT NOT NULL,
    ssl_enabled INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);

-- Metrics History
CREATE TABLE metrics (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    cpu_percent REAL,
    ram_percent REAL,
    disk_percent REAL,
    load_1 REAL,
    load_5 REAL,
    load_15 REAL,
    connections INTEGER,
    bandwidth_in REAL,
    bandwidth_out REAL
);

-- Alerts Log
CREATE TABLE alerts (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    type TEXT NOT NULL,
    severity TEXT NOT NULL,
    message TEXT NOT NULL,
    details TEXT,
    action_taken TEXT,
    acknowledged INTEGER DEFAULT 0
);

-- Blocked IPs
CREATE TABLE blocked_ips (
    id INTEGER PRIMARY KEY,
    ip_address TEXT UNIQUE NOT NULL,
    reason TEXT NOT NULL,
    blocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    permanent INTEGER DEFAULT 0,
    block_count INTEGER DEFAULT 1
);

-- Security Events
CREATE TABLE security_events (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL,
    source_ip TEXT,
    details TEXT,
    severity TEXT
);

-- Indexes for performance
CREATE INDEX idx_metrics_timestamp ON metrics(timestamp);
CREATE INDEX idx_alerts_timestamp ON alerts(timestamp);
CREATE INDEX idx_alerts_type ON alerts(type);
CREATE INDEX idx_blocked_ips_ip ON blocked_ips(ip_address);
CREATE INDEX idx_blocked_ips_expires ON blocked_ips(expires_at);
```

---

*Document Version: 2.0.0 | Last Updated: 2025-12-26*

🐼 **Panda Script** - https://panda-script.com
