# Contributing to Panda Script

Cảm ơn bạn đã quan tâm đến việc đóng góp cho Panda Script! 🐼

## Code of Conduct

Dự án này tuân theo Code of Conduct. Bằng việc tham gia, bạn đồng ý tuân thủ các quy tắc này.

## Cách đóng góp

### Báo cáo bugs

1. Kiểm tra xem bug đã được báo cáo chưa trong [Issues](https://github.com/panda-script/panda-script/issues)
2. Nếu chưa, tạo issue mới với template Bug Report
3. Mô tả chi tiết: OS, phiên bản, bước tái hiện lỗi

### Đề xuất tính năng

1. Kiểm tra trong Issues xem đã có ai đề xuất chưa
2. Tạo issue mới với template Feature Request
3. Giải thích lý do và use case

### Pull Requests

1. Fork repository
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit changes: `git commit -m 'Add: mô tả ngắn'`
4. Push branch: `git push origin feature/ten-tinh-nang`
5. Mở Pull Request

## Coding Standards

### Shell Script
- Sử dụng `#!/bin/bash`
- Indent: 4 spaces
- Quote variables: `"$variable"`
- Check errors với `set -e` hoặc kiểm tra return code
- Comment cho mỗi function

### Commit Messages
```
Type: Short description

- Detail 1
- Detail 2
```

Types: Add, Fix, Update, Remove, Refactor, Docs

## Testing

Test trên tất cả OS hỗ trợ trước khi submit PR:
- Ubuntu 22.04 / 24.04
- Rocky Linux 8 / 9
- AlmaLinux 8 / 9

## Questions?

- **Website**: https://panda-script.com
- **Email**: dev@panda-script.com
- **GitHub**: https://github.com/panda-script

---

🐼 **Panda Script** - https://panda-script.com
