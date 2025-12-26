# Troubleshooting Guide - Panda Script

## Vấn đề thường gặp

### 1. Nginx không khởi động

**Triệu chứng:** `systemctl status nginx` báo failed

**Giải pháp:**
```bash
# Kiểm tra cấu hình
nginx -t

# Xem error log
tail -50 /var/log/nginx/error.log

# Fix permission
chown -R www-data:www-data /var/www
```

### 2. PHP-FPM lỗi

**Triệu chứng:** 502 Bad Gateway

**Giải pháp:**
```bash
# Kiểm tra status
systemctl status php8.3-fpm

# Xem log
tail -50 /var/log/php8.3-fpm.log

# Restart
systemctl restart php8.3-fpm
```

### 3. MariaDB không kết nối được

**Triệu chứng:** Access denied / Connection refused

**Giải pháp:**
```bash
# Kiểm tra status
systemctl status mariadb

# Reset root password
panda -> Database -> Reset Root Password
```

### 4. SSL Certificate lỗi

**Triệu chứng:** Certificate expired / Invalid

**Giải pháp:**
```bash
# Renew manually
certbot renew --force-renewal

# Check certificate
certbot certificates
```

### 5. Telegram alerts không gửi được

**Checklist:**
- [ ] Bot token đúng?
- [ ] Chat ID đúng?
- [ ] Bot đã được add vào group?
- [ ] Server có kết nối internet?

**Test:**
```bash
panda -> Monitoring & Alerts -> Test Telegram
```

### 6. Disk đầy

```bash
# Tìm file lớn
du -sh /* | sort -rh | head -20

# Xóa logs cũ
find /var/log -type f -name "*.log" -mtime +30 -delete

# Xóa backup cũ
find /opt/panda/backup -type f -mtime +7 -delete
```

### 7. RAM cao liên tục

```bash
# Xem process tốn RAM
panda -> Monitoring -> Top Processes

# Clear cache
sync; echo 3 > /proc/sys/vm/drop_caches
```

## Logs

```bash
# Panda Script logs
/opt/panda/logs/

# Nginx logs
/var/log/nginx/

# PHP-FPM logs
/var/log/php8.3-fpm.log

# MariaDB logs
/var/log/mysql/
```

## Liên hệ hỗ trợ

- **Website**: https://panda-script.com
- **Email**: support@panda-script.com
- **GitHub**: https://github.com/panda-script/issues

---

🐼 **Panda Script** - https://panda-script.com
