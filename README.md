# 🏪 TạpHóa App

Ứng dụng quản lý cửa hàng tạp hóa — full-stack gồm backend API và mobile app.

## 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Node.js, Express, PostgreSQL, Sequelize |
| **Mobile** | Flutter (Dart) |
| **Auth** | JWT + Refresh Token |
| **Upload** | Cloudinary (production) / Local (dev) |
| **Push** | Firebase Cloud Messaging |
| **CI/CD** | GitHub Actions + Render |

## 📦 Cấu trúc dự án

```
taphoaapp/
├── backend/          # REST API
│   ├── src/
│   │   ├── controllers/   # Request handlers
│   │   ├── services/      # Business logic
│   │   ├── models/        # Sequelize models
│   │   ├── routes/        # API routing
│   │   ├── middleware/    # Auth, validation, error handling
│   │   ├── validators/    # Joi schemas
│   │   └── utils/         # Helpers (logger, errors, slug)
│   ├── render.yaml        # Render deploy config
│   └── jest.config.js     # Testing config
├── mobile/           # Flutter app
│   └── lib/
│       ├── screens/       # UI screens
│       ├── providers/     # State management
│       ├── models/        # Data models
│       ├── services/      # API service
│       └── widgets/       # Reusable components
└── docker-compose.yml  # Local PostgreSQL
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Flutter 3.x
- PostgreSQL (hoặc Docker)

### Backend

```bash
# 1. Start PostgreSQL
docker compose up -d

# 2. Install & run
cd backend
cp .env.example .env    # Edit với DB credentials
npm install
npm run dev             # http://localhost:3001

# 3. Seed data
npm run db:seed

# 4. API Docs
# Open http://localhost:3001/api/docs
```

### Mobile

```bash
cd mobile
cp .env.example .env    # Edit API_URL
flutter pub get
flutter run
```

## 📋 API Endpoints

### Public

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/health` | Health check |
| GET | `/api/products` | Danh sách sản phẩm |
| GET | `/api/categories` | Danh sách danh mục |
| GET | `/api/config` | Cấu hình shop |

### Auth

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/auth/register` | Đăng ký |
| POST | `/api/auth/login` | Đăng nhập → token + refreshToken |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Đăng xuất |
| POST | `/api/auth/forgot-password` | Yêu cầu OTP |
| POST | `/api/auth/verify-otp` | Xác thực OTP |
| POST | `/api/auth/reset-password` | Đặt lại mật khẩu |

### User (🔒 Auth required)

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/auth/me` | Thông tin user |
| GET | `/api/cart` | Giỏ hàng |
| POST | `/api/orders` | Tạo đơn hàng |
| GET | `/api/notifications` | Thông báo |

### Admin (🔒 Admin role)

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/admin/reports/revenue` | Doanh thu |
| GET | `/api/admin/reports/top-products` | Top sản phẩm |
| GET | `/api/admin/reports/order-stats` | Thống kê đơn |
| GET | `/api/admin/reports/inventory-alerts` | Cảnh báo tồn kho |

## 🧪 Testing

```bash
cd backend
npm test              # Run all tests (62 tests)
npm run test:coverage # With coverage report
```

## 🔐 Security

- JWT access token (15m) + refresh token (30d)
- Rate limiting: 100 req/15min (global), 5 req/15min (auth)
- Helmet security headers
- Joi input validation
- Password hashing (bcryptjs)
- CORS whitelist

## 📱 App Features

**Khách hàng:**

- Đăng ký / Đăng nhập / Quên mật khẩu
- Duyệt sản phẩm theo danh mục
- Tìm kiếm sản phẩm
- Giỏ hàng + Đặt hàng
- Lịch sử đơn hàng
- Quản lý địa chỉ giao hàng
- Thông báo đơn hàng

**Admin:**

- Quản lý sản phẩm (CRUD)
- Quản lý danh mục
- Quản lý đơn hàng (cập nhật trạng thái)
- Quản lý khách hàng
- Cài đặt cửa hàng (phí vận chuyển, thông tin bank)
- Thống kê doanh thu

## 📄 License

MIT
