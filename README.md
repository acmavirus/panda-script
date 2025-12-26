# 🐼 Panda Script v2.2.0
**Ultimate Linux Web Server Automation & Management Assistant**

[![Version](https://img.shields.io/badge/version-2.2.0-blue.svg)](https://github.com/acmavirus/panda-script)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OS](https://img.shields.io/badge/OS-Ubuntu%20|%20Debian%20|%20Rocky-orange.svg)](https://panda-script.com)

Panda Script là một bộ công cụ CLI mạnh mẽ giúp tự động hóa việc cài đặt, cấu hình và quản lý máy chủ web Linux (LEMP Stack) với trọng tâm là bảo mật, hiệu suất và trải nghiệm lập trình viên.

---

## 🚀 Tính năng nổi bật

### 🏗️ Core Stack (LEMP)
-   **Nginx**: Cấu hình tối ưu, hỗ trợ HTTP/2, gRPC.
-   **MariaDB**: Tự động bảo mật và tối ưu hóa database.
-   **PHP**: Hỗ trợ nhiều phiên bản (7.4 - 8.3) với OpCache tích hợp.

### 🌐 Website & App Management
-   **WordPress**: Cài đặt tự động qua CLI, tích hợp WP-CLI.
-   **Node.js**: Quản lý qua NVM & PM2, tự động cấu hình Reverse Proxy.
-   **Website Cloning**: Sao chép website và database chỉ với 1 click.
-   **SSL/HTTPS**: Cấp phát và tự động gian hạn Let's Encrypt (Certbot).

### � Docker & Cache
-   **Docker Engine**: Cài đặt Docker & Docker Compose nhanh chóng.
-   **Container Manager**: Quản lý (Start/Stop/Logs) container trực tiếp từ menu.
-   **High Performance**: Cài đặt và cấu hình Redis, Memcached tự động.

### ☁️ Backup & Reliability
-   **Cloud Backup**: Tích hợp Rclone hỗ trợ Google Drive, S3, Dropbox...
-   **Auto-Heal Engine**: Tự động khởi động lại dịch vụ nếu bị lỗi.
-   **SSL Health Check**: Giám sát và cảnh báo thời hạn chứng chỉ.

### 🛡️ Security Center
-   **Hardening**: SSH hardening, cấm IP (Fail2Ban), Firewall (UFW).
-   **WAF**: Tích hợp 7G Firewall bảo vệ tầng ứng dụng.
-   **SFTP Chroot**: Tạo user SFTP bị giới hạn trong thư mục website.
-   **Malware Scan**: Tích hợp ClamAV quét mã độc định kỳ.

### 👨‍💻 Developer Experience (NEW v2.2)
-   **Panda Deploy**: CI/CD đơn giản (git pull -> install -> build).
-   **Webhook Support**: Tự động deploy khi push code lên GitHub/GitLab.
-   **Log Aggregator**: Xem log nhiều dịch vụ cùng lúc (Tailer).
-   **DB Sync**: Đồng bộ dữ liệu Production -> Staging siêu nhanh.
-   **Cloudflare Tunnel**: Tạo URL demo công khai nhanh không cần mở port.

---

## 🛠️ Cài đặt nhanh

Sử dụng lệnh sau để cài đặt hoặc nâng cấp bản mới nhất:

```bash
curl -sO https://raw.githubusercontent.com/acmavirus/panda-script/main/install && bash install
```

## 📖 Cách sử dụng

Sau khi cài đặt, chỉ cần gõ lệnh sau ở bất cứ đâu:

```bash
panda
```

## 💻 Yêu cầu hệ thống

-   **OS**: Ubuntu 22.04/24.04 (Khuyên dùng), Debian 11/12, Rocky/AlmaLinux 8/9.
-   **RAM**: Tối thiểu 1GB.
-   **Disk**: Trống tối thiểu 10GB.
-   **User**: Quyền Root.

---

## 📄 License

Bản quyền thuộc về [Panda Script](https://panda-script.com). Phát hành dưới giấy phép MIT.
