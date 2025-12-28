# 🐼 Panda Script v3.1.0 (Premium UX)
**Ultimate Linux Web Server Automation & Management Ecosystem**

[![Version](https://img.shields.io/badge/version-3.1.0-blue.svg)](https://github.com/acmavirus/panda-script)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian%20%7C%20Rocky-orange.svg)](https://panda-script.com)

Panda Script là giải pháp quản trị máy chủ toàn diện, kết hợp sức mạnh của **CLI (Command Line Interface) v2.5** và **Web Panel v3.1.0** hiện đại. Biến mọi VPS Linux thành môi trường Web Server chuyên nghiệp, bảo mật và hiệu suất cao chỉ với một dòng lệnh.

---

## 🚀 Tính năng nổi bật (New in v3.1.0)

### 🖥️ Web Panel v3.1.0 (Premium UX)
-   **Dashboard hiện đại**: Theo dõi tài nguyên (CPU, RAM, Disk) theo thời gian thực với biểu đồ mượt mà.
-   **File Manager & Terminal**: Quản lý file trực tiếp trên trình duyệt và tích hợp Terminal Web qua WebSocket.
-   **App Store**: Cài đặt nhanh các ứng dụng phổ biến (Nextcloud, WordPress, n8n, Ghost...) qua Docker.
-   **Notification Center**: Hệ thống thông báo thông minh qua **Telegram, Email** và trực tiếp trên Panel khi có sự kiện hệ thống (Deploy thành công, Server quá tải, v.v.).

### 🌐 Website & App Management
-   **GitHub One-Click Clone**: Hỗ trợ clone source code trực tiếp từ GitHub cho các dự án:
    -   **PHP**: Tự động cài đặt Composer, phân quyền `www-data` và tạo Nginx Vhost.
    -   **Node.js**: Tự động cài đặt NPM dependencies và quản lý qua PM2.
    -   **Python**: Tự động tạo VirtualEnv (Venv) và cài đặt Pip requirements.
    -   **Java**: Hỗ trợ các dự án Spring Boot.
-   **Chuẩn hóa Web Root**: Mọi website được quản lý tập trung tại thư mục `/home` giúp quản trị viên dễ dàng theo dõi và sao lưu.
-   **CMS One-Click**: Cài đặt nhanh WordPress, Joomla, Drupal... hoàn toàn tự động.

### 🛡️ Security & Performance
-   **Panda Doctor**: Hệ thống chẩn đoán sức khỏe server tự động, tính điểm bảo mật và hiệu năng.
-   **SSL Let's Encrypt**: Cấp phát và tự động gia hạn SSL miễn phí chỉ với 1 click.
-   **Firewall & Whitelist**: Quản lý UFW tối giản, bảo vệ các cổng nhạy cảm nhự SSH, Database.
-   **Cache Stack**: Tích hợp sẵn Redis và Memcached giúp tăng tốc website lên tới 300%.

---

## 🛠️ Cài đặt nhanh

Sử dụng script cài đặt hợp nhất (Unified Installer) để cài đặt cả CLI và Web Panel:

```bash
curl -sO https://raw.githubusercontent.com/acmavirus/panda-script/main/install && bash install
```

---

## 📖 Hướng dẫn sử dụng

###  Command Line Interface (CLI)
Gõ lệnh sau để mở Menu quản trị tập trung:
```bash
panda
```

### 🌐 Web Dashboard
Truy cập qua trình duyệt:
-   **URL**: `http://vps-ip:8888/panda` (hoặc port 8080 tùy cấu hình)
-   **Tài khoản mặc định**: `admin`
-   **Mật khẩu mặc định**: `admin`
-   *Lưu ý: Bạn nên đổi mật khẩu ngay sau khi đăng nhập lần đầu.*

---

## 📂 Cấu trúc thư mục hệ thống
-   **Web Root**: `/home` (standardized)
-   **Cấu hình Nginx**: `/etc/nginx/sites-available`
-   **Dữ liệu Panel**: `/opt/panda/data`
-   **Log hệ thống**: `/var/log/panda`

---

## 💻 Yêu cầu hệ thống
-   **Hệ điều hành**: Ubuntu 22.04/24.04 (Khuyên dùng), Debian 11/12, Rocky/AlmaLinux 8/9.
-   **Phần cứng**: Tối thiểu RAM 1GB (Khuyên dùng 2GB trở lên).
-   **Kết nối**: Quyền truy cập Root qua SSH.

---

## 📄 License & Liên hệ
Phát hành bởi **Panda Script Team** dưới giấy phép MIT.
Website: [panda-script.com](https://panda-script.com)
