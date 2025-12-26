# Hướng dẫn cài đặt Panda Script

## Yêu cầu hệ thống

| Thành phần | Tối thiểu | Khuyến nghị |
|------------|-----------|-------------|
| RAM | 1GB | 2GB+ |
| Disk | 5GB | 10GB+ |
| OS | Fresh install | Fresh install |
| Quyền | root/sudo | root |

## Hệ điều hành hỗ trợ

- Ubuntu 22.04 LTS / 24.04 LTS
- Rocky Linux 8 / 9 / 10
- AlmaLinux 8 / 9 / 10
- Debian 11 / 12

## Bước 1: Chuẩn bị VPS

### 1.1 Đảm bảo VPS fresh (chưa cài gì)
```bash
# Kiểm tra các service đang chạy
systemctl list-units --type=service --state=running
```

### 1.2 Update hệ thống
```bash
# Ubuntu/Debian
apt update && apt upgrade -y

# Rocky/AlmaLinux
dnf update -y
```

## Bước 2: Kết nối SSH

```bash
ssh root@your-server-ip
```

Nếu dùng user thường, cấp quyền sudo:
```bash
sudo su
```

## Bước 3: Chạy script cài đặt

```bash
curl -sO https://panda-script.com/install && bash install
```

## Bước 4: Cấu hình trong quá trình cài đặt

Script sẽ hỏi các thông tin sau:

1. **Phiên bản PHP**: 8.2 / 8.3 / 8.4
2. **Phiên bản MariaDB**: 10.11 / 11.4 / 11.8  
3. **Email admin**: Để nhận thông báo
4. **Telegram Bot Token**: Để nhận cảnh báo (optional)
5. **Telegram Chat ID**: Chat ID để gửi alert (optional)

## Bước 5: Hoàn tất

Sau 10-30 phút, script sẽ hiển thị thông tin:

```
╔════════════════════════════════════════════════════════════╗
║       🐼 Panda Script Installed Successfully!              ║
╠════════════════════════════════════════════════════════════╣
║ Management Command:  panda                                 ║
║ Admin Email:         admin@example.com                     ║
║ PHP Version:         8.3                                   ║
║ MariaDB Version:     11.4                                  ║
║                                                            ║
║ MySQL Root Password: ****************                      ║
║ Telegram Alerts:     ✓ Configured                          ║
╚════════════════════════════════════════════════════════════╝
```

## Sử dụng

Gọi menu quản lý:
```bash
panda
```

## Cấu hình Telegram Alerts

### Tạo Bot
1. Mở Telegram, tìm @BotFather
2. Gửi `/newbot`
3. Đặt tên và username cho bot
4. Copy **Bot Token**

### Lấy Chat ID
1. Mở @userinfobot hoặc @getidsbot
2. Gửi `/start`
3. Copy **Chat ID**

### Cập nhật config
```bash
panda -> Monitoring & Alerts -> Configure Telegram
```

## Troubleshooting

### Script không chạy được
```bash
chmod +x install
bash install
```

### Lỗi kết nối mạng
```bash
ping -c 3 panda-script.com
curl -I https://panda-script.com
```

### Kiểm tra logs
```bash
cat /opt/panda/logs/install.log
```

---

🐼 **Panda Script** - https://panda-script.com
