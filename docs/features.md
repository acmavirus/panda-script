# Tính năng Panda Script v2.0

## 🔔 1. Monitoring & Alerts

### Monitoring Daemon (24/7)
- CPU, RAM, Disk, Network metrics
- Service health check (nginx, php-fpm, mysql)
- Load average tracking
- Connection monitoring

### Alert Channels
- **Telegram Bot**: Real-time alerts với templates đẹp
- **Email**: SMTP notifications
- **Discord**: Webhook integration
- **Custom Webhook**: API calls

### Alert Types
| Type | Trigger | Action |
|------|---------|--------|
| DDoS Attack | >500 conn/IP | Block + Alert |
| RAM Full | >90% | Clear cache + Alert |
| System Hang | No response 30s | Auto restart + Alert |
| Service Down | nginx/php/mysql | Auto restart + Alert |
| SSL Expiring | <7 days | Alert |

---

## 🛡️ 2. DDoS Protection

### Detection
- Connection rate analysis
- Request pattern detection
- Bandwidth spike detection
- SYN/UDP flood detection
- HTTP flood detection

### Mitigation
- Auto IP blocking
- Rate limiting activation
- Geo-blocking (optional)
- Cloudflare API integration

### Thresholds (configurable)
- Warning: 100 conn/IP
- Critical: 300 conn/IP
- Block: 500 conn/IP

---

## 🔒 3. Security (5 Layers)

### Layer 1: Network Firewall
- firewalld/ufw/iptables
- Rate limiting
- Port management
- Geo-blocking

### Layer 2: Intrusion Detection
- fail2ban (SSH, HTTP, custom jails)
- AIDE file integrity
- Rootkit detection
- Malware scanning (ClamAV)

### Layer 3: SSH Hardening
- Key-based auth
- Max retry limits
- Custom port
- 2FA support

### Layer 4: Kernel Hardening
- TCP SYN cookies
- IP spoofing protection
- ASLR enabled
- Secure memory

### Layer 5: Application Security
- PHP disable_functions
- open_basedir
- Security headers
- SSL/TLS hardening

---

## 🚀 4. Performance Optimization

### Auto-Tuning
- RAM-based configuration
- CPU-based workers
- Dynamic adjustment

### Caching
- PHP OPcache
- Redis/Memcached
- Nginx FastCGI cache
- Browser caching

### Kernel Tuning
- Network stack optimization
- File descriptor limits
- TCP optimization

---

## 🌐 5. Website Management
- Create/Delete/List websites
- Nginx virtual hosts
- PHP-FPM pools per site
- WordPress quick install
- Laravel deployment

## 📊 6. Database Management
- Create/Delete databases
- User management
- Backup/Restore
- Performance tuning

## 🔐 7. SSL/HTTPS
- Let's Encrypt auto
- Self-signed certs
- Auto-renewal
- Status monitoring

## 💾 8. Backup System
- Local backup (files + DB)
- Remote (SFTP, S3)
- Google Drive (rclone)
- Scheduled backup
- Retention policy

## 🐘 9. PHP Management
- Version switching (8.2/8.3/8.4)
- Extension management
- Config tuning
- OPcache control

## ⚙️ 10. System Configuration
- Timezone settings
- SSH port change
- Hostname settings
- Auto updates

---

🐼 **Panda Script** - https://panda-script.com
