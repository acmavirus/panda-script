# Panda Script v2.0
## Auto Configuration & Management Assistant

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Linux-orange.svg)
![Security](https://img.shields.io/badge/security-hardened-red.svg)

---

## 🐼 Giới thiệu

**Panda Script v2.0** là công cụ tự động hóa cài đặt và quản lý web server với các tính năng nâng cao:

- 🚀 **Hiệu suất cao**: Auto-tuning theo RAM, kernel optimization
- 🛡️ **Bảo mật đa lớp**: Firewall, fail2ban, DDoS protection, AIDE
- 📢 **Cảnh báo thông minh**: Telegram, Email, Discord, Webhook
- 📊 **Monitoring 24/7**: DDoS, RAM, CPU, Disk, Services
- ⚡ **Auto-mitigation**: Tự động xử lý các vấn đề

---

## 🔔 Hệ thống Cảnh báo

### Telegram Bot Integration

Nhận cảnh báo real-time qua Telegram khi:

| Sự kiện | Mô tả | Severity |
|---------|-------|----------|
| 🔥 DDoS Attack | Phát hiện tấn công DDoS | 🔴 Critical |
| 💾 RAM Full | RAM > 90% | 🔴 Critical |
| 💾 RAM High | RAM > 80% | 🟡 Warning |
| 🖥️ System Hang | Hệ thống không phản hồi | 🔴 Critical |
| ⚙️ CPU Overload | CPU > 95% trong 5 phút | 🟡 Warning |
| 💿 Disk Full | Disk > 90% | 🔴 Critical |
| 🔧 Service Down | nginx/php/mysql ngừng | 🔴 Critical |
| 🔐 SSH Brute Force | Tấn công SSH | 🟡 Warning |
| 🔒 SSL Expiring | SSL hết hạn < 7 ngày | 🟡 Warning |

### Ví dụ cảnh báo Telegram

```
🐼 PANDA SCRIPT ALERT
🔥 DDoS ATTACK DETECTED

Server: web-server-01
Time: 2025-12-26 23:00:00

━━━━━━━━━━━━━━━━━━━━
📊 Attack Info:
• Type: HTTP Flood
• Source IPs: 156
• Connections/sec: 2,847
• Bandwidth: 450 Mbps

🎯 Top Attackers:
1. 192.168.1.100 (847 conn)
2. 10.0.0.50 (623 conn)
3. 172.16.0.25 (412 conn)

⚡ Mitigation: Active
• 156 IPs blocked
• Rate limiting enabled
━━━━━━━━━━━━━━━━━━━━
```

---

## 🛡️ Bảo mật đa lớp

```
Internet
    │
    ▼
┌─────────────────────────────────┐
│ Layer 1: CDN (Cloudflare)       │
│ • DDoS mitigation at edge       │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Layer 2: Network Firewall       │
│ • iptables/nftables             │
│ • Rate limiting                 │
│ • Geo-blocking                  │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Layer 3: Application Firewall   │
│ • fail2ban                      │
│ • Nginx rate limit              │
│ • Bad bot blocking              │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Layer 4: System Hardening       │
│ • SSH hardening                 │
│ • AIDE integrity                │
│ • Kernel hardening              │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Layer 5: Application Security   │
│ • PHP sandbox                   │
│ • open_basedir                  │
│ • Security headers              │
└─────────────────────────────────┘
```

---

## ⚙️ Thành phần cài đặt

### LEMP Stack
- **Nginx**: Latest stable + optimized config
- **MariaDB**: 10.11 / 11.4 / 11.8
- **PHP**: 8.2 / 8.3 / 8.4 + OPcache

### Monitoring & Security
- **Monitoring Daemon**: 24/7 system monitoring
- **DDoS Detector**: Real-time attack detection
- **fail2ban**: Brute force protection
- **AIDE**: File integrity monitoring
- **ClamAV**: Malware scanning

### Alert Channels
- **Telegram Bot**: Primary alerts
- **Email**: SMTP notifications
- **Discord**: Webhook alerts
- **Custom Webhook**: API integration

---

## 📊 Menu quản lý

```bash
panda
```

```
╔══════════════════════════════════════════════════════════════╗
║          🐼 Panda Script v2.0 - Server Management            ║
╠══════════════════════════════════════════════════════════════╣
║  1. 🌐 Website Management                                    ║
║  2. 📊 Database Management                                   ║
║  3. 🔒 SSL/HTTPS Management                                  ║
║  4. 💾 Backup & Restore                                      ║
║  5. 🐘 PHP Management                                        ║
║  6. 🔧 Nginx Management                                      ║
║  7. 📈 Monitoring & Alerts                                   ║
║  8. 🛡️  Security Center                                      ║
║  9. ⚡ Performance Tuning                                    ║
║  10. ⚙️  System Configuration                                 ║
║  0. ❌ Exit                                                   ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 🚀 Cài đặt

```bash
curl -sO https://panda-script.com/install && bash install
```

## 📋 Yêu cầu

| Thành phần | Tối thiểu | Khuyến nghị |
|------------|-----------|-------------|
| RAM | 1GB | 2GB+ |
| Disk | 10GB | 20GB+ |
| OS | Fresh install | Fresh install |

### Hệ điều hành hỗ trợ
- Ubuntu 22.04 / 24.04
- Rocky Linux 8 / 9 / 10
- AlmaLinux 8 / 9 / 10
- Debian 11 / 12

---

## 📚 Tài liệu

- [Kiến trúc hệ thống](./architecture.md)
- [Hướng dẫn cài đặt](./installation.md)
- [Danh sách tính năng](./features.md)
- [Kế hoạch triển khai](./implementation-plan.md)
- [Xử lý sự cố](./troubleshooting.md)
- [Changelog](./changelog.md)

---

## 🌐 Website & Support

- **Website**: [https://panda-script.com](https://panda-script.com)
- **Documentation**: [https://docs.panda-script.com](https://docs.panda-script.com)
- **GitHub**: [https://github.com/panda-script](https://github.com/panda-script)

---

## 📄 License

MIT License - Xem file [LICENSE](../LICENSE)

---

**🐼 Panda Script v2.0** - Secure, Fast, Monitored 🚀
