# PLAN: Mobile App Improvements — TạpHóa Shop

> **Date**: 2026-03-08
> **Status**: ✅ P0 + P1 + P2 + P3 + P4 COMPLETED
> **Scope**: Flutter mobile app (`mobile/`)
> **Mục tiêu**: Nâng cao chất lượng code, UX, performance và stability

---

## 📊 Tổng quan phân tích

Sau khi review toàn bộ 31 screens, 6 providers, 2 services, 7 models, 4 widgets, và cấu hình dự án, tôi chia các vấn đề thành **6 nhóm ưu tiên** từ Critical → Nice-to-have.

---

## 🔴 P0 — CRITICAL (Nên fix ngay)

### 1. Hardcoded Shipping Fee trong `cart_screen.dart`

- **File**: `screens/cart_screen.dart` (line 18-19)
- **Vấn đề**: `freeShipThreshold` và `shippingFee` bị hardcode (`150000`, `10000`), trong khi `checkout_screen.dart` đã dùng dynamic rules từ API `/config`
- **Hậu quả**: User thấy phí ship khác nhau giữa trang Giỏ hàng vs trang Đặt hàng
- **Fix**: Load config từ API `/config` hoặc dùng shared state (provider) cho shipping rules

### 2. Không có Retry/Timeout cho API calls

- **File**: `services/api_service.dart`
- **Vấn đề**: Không có `timeout` cho HTTP requests → app bị treo nếu server chậm/mất kết nối
- **Fix**: Thêm `.timeout(Duration(seconds: 15))` cho tất cả requests, thêm retry logic cho failures tạm thời

### 3. Không có Error Handling toàn cục

- **Vấn đề**: Mỗi provider tự xử lý error, nhiều nơi nuốt exception (`catch (_) {}`) — nhất là push notification init (auth_provider.dart line 65, 105)
- **Fix**: Centralized error handler + ErrorBoundary widget

### 4. Models thiếu `copyWith` và `toJson`

- **File**: Tất cả models (user.dart, product.dart, order.dart, etc.)
- **Vấn đề**: Chỉ có `fromJson`, không có `toJson` → khó serialize lại. Notification model tạo lại object thủ công thay vì dùng `copyWith` (notification_provider.dart line 45-58)
- **Fix**: Thêm `copyWith()` và `toJson()` cho tất cả models

---

## 🟠 P1 — HIGH (Nên fix sớm)

### 5. Tính năng "Sản phẩm yêu thích" không hoạt động

- **File**: `screens/profile_screen.dart` (line 144)
- **Vấn đề**: `onTap: () {}` — nút "Sản phẩm yêu thích" chưa có logic
- **Fix**: Implement Wishlist hoặc ẩn menu item cho tới khi feature sẵn sàng

### 6. Tính năng "Trợ giúp & Hỗ trợ" không hoạt động

- **File**: `screens/profile_screen.dart` (line 174)
- **Vấn đề**: `onTap: () {}` — nút chưa có logic
- **Fix**: Thêm trang FAQ/liên hệ hoặc ẩn tạm

### 7. Tìm kiếm product gọi API mỗi keystroke

- **File**: `screens/home_screen.dart` (line 161)
- **Vấn đề**: `onChanged` trigger `searchProducts()` trực tiếp → quá nhiều API calls
- **Fix**: Thêm debounce (300-500ms) trước khi gọi API

### 8. Tìm kiếm trong CategoriesScreen không hoạt động

- **File**: `screens/categories_screen.dart` (line 108-124)
- **Vấn đề**: Search bar chỉ là UI tĩnh (GestureDetector mà không có onTap handler)
- **Fix**: Wire search bar vào logic tìm product, hoặc navigate về HomeScreen search

### 9. Không có Pagination cho Products

- **File**: `providers/product_provider.dart`
- **Vấn đề**: Load tất cả products cùng lúc, không có infinite scroll hoặc load more
- **Fix**: Implement cursor/offset pagination với `ScrollController`

### 10. Không có Refresh Token logic

- **File**: `services/api_service.dart`, `providers/auth_provider.dart`
- **Vấn đề**: Chỉ lưu 1 access token. Khi token expire, user bị kick ra login mà không có auto-refresh
- **Fix**: Implement token refresh interceptor (dùng refresh token nếu backend hỗ trợ, hoặc silent re-auth)

---

## 🟡 P2 — MEDIUM (Cải thiện UX)

### 11. Notification tap không navigate đến order

- **File**: `screens/notifications_screen.dart` (line 122-125)
- **Vấn đề**: Tap vào notification chỉ mark as read, không navigate sang order detail
- **Fix**: Check `referenceType == 'order'` → navigate to `/order-detail`

### 12. Không có Empty State Animation

- **Vấn đề**: Các empty state (giỏ hàng trống, notification trống) chỉ dùng static icon
- **Fix**: Thêm Lottie animation hoặc `flutter_animate` cho empty states

### 13. Cart Screen không refetch khi mở lại

- **File**: `screens/cart_screen.dart`
- **Vấn đề**: `CartScreen` là `StatelessWidget`, không gọi `loadCart()` khi mở lại → có thể show data cũ nếu giỏ hàng bị thay đổi ở nơi khác
- **Fix**: Chuyển sang StatefulWidget và gọi refetch trong initState

### 14. Loading state chưa có Skeleton/Shimmer

- **Vấn đề**: Tất cả loading dùng `CircularProgressIndicator` chung → UX rất basic
- **Fix**: Implement shimmer/skeleton loading cho product grid, cart items, notifications

### 15. Home Banner hardcoded nội dung

- **File**: `screens/home_screen.dart` (line 185-226)
- **Vấn đề**: Banner content bị cứng ("Miễn phí ship từ 150K", "Hàng tiêu dùng, thực phẩm & gia vị")
- **Fix**: Lấy banner data từ API hoặc đồng bộ với config shipping rules

### 16. Không có thông báo badge trên BottomNav

- **File**: `screens/main_screen.dart`
- **Vấn đề**: Notification tab không hiển thị unread count badge
- **Fix**: Thêm `Consumer<NotificationProvider>` cho notification tab icon

---

## 🔵 P3 — LOW (Code Quality)

### 17. Screen files quá lớn, thiếu decomposition

- **File**: `checkout_screen.dart` (474 lines), `categories_screen.dart` (469 lines), `cart_screen.dart` (215 lines)
- **Fix**: Tách các widget con ra file riêng (e.g. `widgets/checkout/`, `widgets/categories/`)

### 18. Thiếu Theme Extension cho reusable styles

- **Vấn đề**: Hardcode `TextStyle`, `BoxDecoration` trực tiếp trong widgets. Ví dụ: `const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)` lặp lại khắp nơi
- **Fix**: Tạo `AppTextStyles`, `AppDecorations` classes hoặc Flutter Theme extensions

### 19. Provider dùng `watch` nơi chỉ cần `read`

- **Vấn đề**: Một số chỗ dùng `context.watch()` trong những widget chỉ cần 1 lần read → rebuild không cần thiết
- **Fix**: Audit và chuyển sang `context.read()` hoặc `Consumer` ở đúng chỗ

### 20. Duplicate API call logic trong CategoriesScreen

- **File**: `screens/categories_screen.dart` (line 21, 57)
- **Vấn đề**: Tạo riêng `ApiService _api` instance và gọi API trực tiếp thay vì qua Provider
- **Fix**: Tạo `CategoryProvider` chuyên biệt hoặc extend `ProductProvider`

### 21. Format tiền tệ không nhất quán

- **Vấn đề**: `NumberFormat('#,###', 'vi_VN')` vs `NumberFormat('#,##0', 'vi_VN')` dùng lẫn lộn
- **Fix**: Tạo utility `formatCurrency()` centralized

---

## ⚪ P4 — NICE TO HAVE

### 22. Không có Unit Tests

- **File**: `test/widget_test.dart` — chỉ có 1 test file mặc định của Flutter
- **Fix**: Thêm unit tests cho models, providers và API service

### 23. Không có App Icon / Launcher Screen custom

- **Vấn đề**: Vẫn dùng Flutter default icon
- **Fix**: Tạo app icon thương hiệu TạpHóa Shop, dùng `flutter_launcher_icons`

### 24. Không có Deep Linking

- **Vấn đề**: Push notification không navigate đến screen tương ứng khi tap
- **Fix**: Implement deep link handler cho FCM `onMessageOpenedApp`

### 25. Không có Offline Support

- **Vấn đề**: App không cache gì, mất mạng = app trống
- **Fix**: Local cache cho products (dùng `sqflite` hoặc `hive`), optimistic UI

### 26. Không có Image Compression trước upload

- **File**: `services/api_service.dart` (uploadImage)
- **Fix**: Resize + compress image trước khi upload (dùng `flutter_image_compress`)

### 27. Missing pull-to-refresh ở nhiều screens

- **Vấn đề**: Chỉ HomeScreen có `RefreshIndicator`, CartScreen/OrderHistoryScreen/ProfileScreen thiếu
- **Fix**: Thống nhất pull-to-refresh across screens

---

## 📋 Kế hoạch thực hiện theo Phase

### Phase 1: Bug Fixes & Stability (1-2 ngày)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 1 | Fix hardcoded shipping fee | cart_screen.dart | P0 |
| 2 | Add API timeout | api_service.dart | P0 |
| 3 | Add search debounce | home_screen.dart | P1 |
| 4 | Fix notification navigate | notifications_screen.dart | P2 |
| 5 | Add unread badge to nav | main_screen.dart | P2 |
| 6 | Fix/hide broken menu items | profile_screen.dart | P1 |

### Phase 2: UX Enhancement (2-3 ngày)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 7 | Add shimmer loading | New widget + các screens | P2 |
| 8 | Add models copyWith | all models | P0 |
| 9 | Fix categories search | categories_screen.dart | P1 |
| 10 | Add pull-to-refresh | cart, orders, profile | P4 |
| 11 | Dynamic banner content | home_screen.dart | P2 |

### Phase 3: Architecture & Performance (2-3 ngày)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 12 | Product pagination | product_provider + home | P1 |
| 13 | Centralized formatCurrency | New utils file | P3 |
| 14 | Split large screens | checkout, categories | P3 |
| 15 | Fix Provider watch/read | Multiple screens | P3 |

### Phase 4: Testing & Polish (2-3 ngày)

| # | Task | Files | Priority |
|---|------|-------|----------|
| 16 | Unit tests cho models | test/ | P4 |
| 17 | Unit tests cho providers | test/ | P4 |
| 18 | Custom app icon | pubspec + assets | P4 |
| 19 | Deep linking for FCM | push_notification_service | P4 |

---

## ❓ Câu hỏi cần user trả lời

Trước khi bắt tay implement, cần xác nhận:

1. **Wishlist feature**: Muốn implement đầy đủ hay ẩn tạm menu "Sản phẩm yêu thích"?
2. **Backend refresh token**: Backend có hỗ trợ refresh token không? (Hiện chỉ thấy 1 JWT token)
3. **Offline support**: Có cần cache sản phẩm offline không? Hay app chỉ cần internet?
4. **Banner**: Banner trên trang chủ muốn lấy từ admin config hay giữ tĩnh?
5. **Phase nào ưu tiên?** Muốn fix bug P0 trước hay enhance UX trước?

---

> **Next steps**: Review plan này → Trả lời các câu hỏi → Run `/create` hoặc bắt tay fix từng phase
