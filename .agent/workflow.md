---
description: UI Design Guidelines - Panda Panel v3
---

## 🏗️ Giai đoạn 1: Thiết lập Hệ tư tưởng Thiết kế (Design Language)

CloudPanel đẹp vì nó **"Biết từ chối"**. Đừng cố nhồi nhét mọi thứ lên một màn hình.

* **Bảng màu (Palette):** Sử dụng các tông màu Neutral (Xám/Trắng) làm chủ đạo. Điểm xuyết bằng một màu thương hiệu (Primary Color) duy nhất (ví dụ: Xanh Navy đậm hoặc Đen Panda).
* **Typography:** Sử dụng các Font chữ Sans-serif hiện đại, chuyên dụng cho Dashboard như **Inter**, **Geist** hoặc **Roboto**. Khoảng cách dòng (Line-height) phải rộng để mắt không bị mỏi.
* **Iconography:** Sử dụng bộ icon mảnh (Stroke 1.5px) như **Lucide Icons** hoặc **Tabler Icons**. Tuyệt đối không dùng icon nhiều màu sắc lòe loẹt.

### ✅ Đã triển khai:
- [x] Font: Inter + JetBrains Mono
- [x] Color Palette: Neutral base (#0a0a0b) + Primary Accent (#f59e0b)
- [x] Icons: Lucide Vue Next (stroke 1.5px)

---

## 📐 Giai đoạn 3: Cấu trúc Layout (Information Architecture)

Giao diện nên chia làm 3 khu vực chính, cố định để người dùng không bao giờ bị "lạc":

1. **Sidebar (Thanh bên):** Chỉ chứa các mục lớn (Sites, Databases, Security, Settings, Terminal).
2. **Top Navigation:** Chứa Global Search (Ctrl+K), Thông báo (Notification), và System Health Badge (Trạng thái server).
3. **Main Content area:** Khu vực làm việc chính. Sử dụng **White Space (Khoảng trắng)** rộng rãi để tách biệt các khối dữ liệu.

### ✅ Đã triển khai:
- [x] Sidebar với menu dividers, badges cho mục mới
- [x] Top Nav: Command Palette (Ctrl+K), System Health Badge, Theme Toggle
- [x] Main Content: Padding generous (p-8), max-width constraint

---

## 🚀 Giai đoạn 4: Workflow Phát triển (Implementation)

### Bước 1: UI Components Library ✅

Đã xây dựng bộ thư viện Component:

* **Card** - `components/Card.vue`
* **StatusIndicator** - `components/StatusIndicator.vue` 
* **Skeleton** - `components/Skeleton.vue`
* **CommandPalette** - `components/CommandPalette.vue`
* **Minimal Table** - CSS class `.panda-table`

### Bước 2: Skeleton Loading ✅

Thay vì vòng xoay Loading (Spinner), đã implement **Skeleton Screens**:
- Dashboard Stats: skeleton-stats
- Tables: skeleton table-row
- Lists: skeleton-list

### Bước 3: Backend Integration (Go `embed`) ✅

1. Build Frontend (`npm run build`) ra thư mục `/dist`
2. Dùng `//go:embed dist/*` để nhúng vào binary
3. Sử dụng Gzip Compression

---

## ✨ Giai đoạn 5: "Gia vị" cho sự Sang trọng (The Panda Touch)

### ✅ Đã triển khai:

* **Optimistic UI:** 
  - Websites page: Thêm site hiển thị ngay, xóa trước khi API response
  - Services page: Trạng thái update ngay khi click Start/Stop/Restart

* **Contextual Actions:**
  - Table rows: Actions ẩn, chỉ hiện khi hover (class `.contextual-actions`)
  - CSS: `opacity: 0` → `opacity: 1` on parent hover

* **Keyboard First:**
  - Command Palette: Ctrl+K / Cmd+K
  - Theme Toggle: Ctrl+T / Cmd+T
  - Arrow keys trong Command Palette để navigate
  - Enter để select

---

## 📁 Files đã tạo/cập nhật

### CSS Design System
- `src/style.css` - Complete redesign với:
  - CSS Variables cho colors, spacing, shadows
  - `.panda-card`, `.panda-table`, `.panda-btn`, `.panda-badge`, `.panda-input`
  - `.skeleton`, `.status-indicator`, `.contextual-actions`
  - `.command-palette`, `.kbd`

### Components
- `src/components/Skeleton.vue` - Skeleton loading
- `src/components/StatusIndicator.vue` - Status dots (online/offline)
- `src/components/Card.vue` - Reusable card
- `src/components/CommandPalette.vue` - Command palette (Ctrl+K)

### Views Updated
- `src/views/Dashboard.vue` - Skeleton, Better charts
- `src/views/Websites.vue` - Minimal table, Optimistic UI
- `src/views/Services.vue` - Contextual actions
- `src/views/Login.vue` - Split layout, Branding

### Layout
- `src/layouts/MainLayout.vue` - Command palette, Health badge, Simplified menu
- `src/App.vue` - Keyboard shortcuts

---

## 🎨 Color Palette

```css
/* Neutral Base */
--bg-base: #0a0a0b;
--bg-elevated: #111113;
--bg-surface: #18181b;
--bg-hover: #27272a;

/* Text */
--text-primary: #fafafa;
--text-secondary: #a1a1aa;
--text-muted: #71717a;

/* Primary Accent */
--color-primary: #f59e0b;

/* Status */
--color-success: #22c55e;
--color-warning: #f59e0b;
--color-error: #ef4444;
--color-info: #3b82f6;
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + K` | Open Command Palette |
| `Ctrl/Cmd + T` | Toggle Theme |
| `↑ ↓` | Navigate Command Palette |
| `Enter` | Select item |
| `Escape` | Close modals/palette |

---

## 🌐 Deployment Environments & Strategy

Panda Script standardizes on a **Two-Stage Deployment** process to ensure production stability.

### Servers
*   **Test Environment**: `*.52`
*   **Production Environment**: `*.123`

### The Golden Rule
> **Phát triển -> Test -> Production**
> Tuyệt đối không cập nhật trực tiếp lên Production. Mọi chức năng mới phải được cài đặt và kiểm thử trên server Test (`*.52`) trước. Chỉ khi xác nhận không có lỗi mới được đồng bộ lên Production (`*.123`).

### ✅ Đã cấu hình:
- [x] SSH Key sync cho cả 2 server
- [x] Standardized Web Root: `/home` cho cả 2 server
- [x] Go v1.24 + Node.js v20 môi trường đồng nhất
- [x] Workflow tự động: `.agent/workflows/deploy.md`
