# 🐼 Panda Script v2.2.0
**Ultimate Linux Web Server Automation & Management Assistant**

[![Version](https://img.shields.io/badge/version-2.2.0-blue.svg)](https://github.com/acmavirus/panda-script)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OS](https://img.shields.io/badge/OS-Ubuntu%20|%20Debian%20|%20Rocky-orange.svg)](https://panda-script.com)

Panda Script là giải pháp CLI toàn diện giúp biến một máy chủ Linux trắng thành một Web Server mạnh mẽ, bảo mật và dễ quản lý chỉ trong vài phút.

---

## 🚀 Danh sách tính năng đầy đủ

### 🏗️ Core Stack (LEMP Standard)
-   **Nginx Mainline**: Tự động cấu hình tối ưu, bảo mật header, hỗ trợ Gzip/Brotli, HTTP/2.
-   **MariaDB/MySQL**: Cài đặt bản stable, tự động chạy `mysql_secure_installation`, quản lý user/db qua CLI.
-   **PHP Multiple Versions**: Hỗ trợ đồng thời nhiểu bản PHP (7.4, 8.0, 8.1, 8.2, 8.3) với PHP-FPM.
-   **Performance Tuning**: Tự động tinh chỉnh thông số Kernel, Nginx và PHP dựa trên tài nguyên phần cứng (RAM/CPU).

### 🌐 Website Management
-   **Vhost Creator**: Tạo VirtualHost Nginx chuẩn chỉ, tự động tạo thư mục và phân quyền.
-   **WordPress One-Click**: Tự động tải, cài đặt WP, tạo Database và cấu hình `wp-config.php`. Tích hợp sẵn **WP-CLI**.
-   **Node.js & PM2**: Cài đặt NVM, Node.js, PM2 và setup Reverse Proxy tự động cho ứng dụng Node.
-   **Website Cloning**: Nhân bản website và database sang domain mới hoặc môi trường Staging/Dev.
-   **SSL Let's Encrypt**: Tự động cấp phát, gia hạn SSL cho domain/subdomain và redirect HTTP -> HTTPS.

### 🐋 Docker & Performance
-   **Docker Hub**: Cài đặt Docker Engine và Docker Compose bản mới nhất.
-   **Container Dashboard**: Menu CLI giúp Xem danh sách, Khởi động, Dừng và Xem log container.
-   **Advanced Caching**:
    -   **Redis**: Cài đặt và cấu hình làm Object Cache.
    -   **Memcached**: Hỗ trợ tăng tốc truy vấn database.
    -   **PHP OpCache**: Công cụ quản lý và xóa cache OpCache qua CLI.

### ☁️ Backup & Reliability
-   **Local Backup**: Nén mã nguồn và dump database tự động theo lịch trình.
-   **Cloud Backup (Rclone)**: Đồng bộ bản sao lưu lên Google Drive, S3, Dropbox, Onedrive...
-   **Auto-Heal Engine**: Dịch vụ nền tự động theo dõi và "cứu sống" Nginx/PHP/MySQL/Redis nếu bị crash.
-   **Monitoring**: Theo dõi tài nguyên hệ thống (CPU, RAM, Disk) thời gian thực.

### 🛡️ Security Center
-   **Firewall (UFW)**: Tự động quản lý đóng/mở port an toàn.
-   **Fail2Ban**: Bảo vệ server khỏi tấn công Brute Force (SSH, Nginx, WordPress).
-   **SSH Hardening**: Đổi port SSH, tắt root login, sử dụng SSH Key.
-   **7G Firewall (WAF)**: Lớp bảo vệ Nginx chống SQL Injection, XSS và Bad Bots.
-   **SFTP Jailed**: Tạo tài khoản SFTP bị giới hạn truy cập (chroot) trong thư mục website.
-   **Malware Scan**: Sử dụng ClamAV để quét và cảnh báo mã độc trong mã nguồn.

### 👨‍💻 Developer Experience (DevXP)
-   **Panda Deploy**: CI/CD siêu nhẹ, tự động `git pull` và chạy build (Composer/NPM/Artisan) khi đẩy code.
-   **Log Aggregator**: Xem mọi loại log (Nginx, PHP, App) tập trung trên một màn hình duy nhất.
-   **Database Sync**: Clone nhanh database Production về Local/Staging để debug.
-   **Cloudflare Tunnel**: Tạo public URL tạm thời trỏ thẳng vào port server để demo.
-   **Fix Permissions**: Công cụ "vạn năng" sửa lỗi 403/500 do sai quyền thư mục.

### 🛠️ System Utilities
-   **Swap Manager**: Tạo hoặc mở rộng bộ nhớ Swap cho server ít RAM.
-   **Junk Cleaner**: Dọn dẹp log cũ, cache và file tạm để giải phóng dung lượng đĩa.
-   **Composer/NVM**: Quản lý các công cụ dependency cho dev.
-   **Cronjob Manager**: Quản lý các tiến trình chạy ngầm dễ dàng qua CLI.

---

## 🛠️ Cài đặt & Nâng cấp

```bash
curl -sO https://raw.githubusercontent.com/acmavirus/panda-script/main/install && bash install
```

## 📖 Cách sử dụng

```bash
panda
```

## 💻 Yêu cầu hệ thống

-   **Hệ điều hành**: Ubuntu 22.04/24.04, Debian 11/12, Rocky/AlmaLinux 8/9.
-   **Phần cứng**: RAM >= 1GB, Disk >= 10GB.

---

## 📄 License & Liên hệ

Phát hành bởi [Panda Script](https://panda-script.com) dưới giấy phép MIT.
