# PLAN: Full Polish — Mobile Customer Screens

> **Created:** 2026-03-08  
> **Scope:** Customer-facing screens only (không bao gồm Admin)  
> **Agent:** `mobile-developer`  
> **Status:** ⏳ Pending

---

## 📋 Tổng quan

Full polish cho TạpHóa mobile app, tập trung vào **visual excellence**, **structural quality**, và **branding** cho tất cả customer-facing screens. Trọng tâm đặc biệt: `HomeScreen` và `ProductDetailScreen`.

### Phạm vi

| Bao gồm | Không bao gồm |
|----------|----------------|
| Home, Product Detail, Cart, Checkout, Categories, Profile, Login, Register, Splash, Wishlist, Orders, Notifications, Addresses | Admin screens (12 files) |
| Shared widgets (5 files) | Backend changes |
| App icon & splash branding | New features/functionality |
| Structural refactoring | Admin-specific polish |

---

## Phase 1: Design System Foundation 🎨
>
> **Priority:** P0 — Must be done first, all other phases depend on this  
> **Estimated effort:** Small

### Task 1.1: Mở rộng `AppColors` với Design Tokens

**File:** `lib/constants/app_colors.dart`

**Thêm:**

- `divider` color (hiện dùng hardcoded `Colors.grey.withValues(alpha: 0.15)` rải rác)
- `shimmerBase` / `shimmerHighlight` (extract từ `shimmer_loading.dart`)
- `successLight`, `warningLight`, `errorLight` backgrounds (extract từ cart_screen shipping bar)
- `overlayDark` / `overlayLight` cho glassmorphism buttons
- `cardRadius`, `buttonRadius`, `chipRadius` constants (hiện hardcoded 18, 14, 22... rải rác)

**Lý do:** Hiện có ít nhất 8+ nơi dùng `withValues(alpha: ...)` inline. Chuẩn hoá giúp consistency + dễ maintain.

### Task 1.2: Tạo `AppSpacing` constants

**File mới:** `lib/constants/app_spacing.dart`

**Nội dung:**

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  
  static const double cardRadius = 18;
  static const double buttonRadius = 14;
  static const double chipRadius = 22;
  static const double bottomSheetRadius = 24;
}
```

**Lý do:** Spacing không nhất quán: card padding dùng 10, 12, 14, 16, 20 tuỳ screen.

### Task 1.3: Tạo `AppTextStyles` centralized

**File mới:** `lib/constants/app_text_styles.dart`

**Extract từ inline styles:**

- `headlineLarge` (22–26px, w700–w800)
- `headlineMedium` (17–18px, w700)
- `bodyLarge` (15–16px, w500–w600)
- `bodyMedium` (13–14px, w400–w500)
- `bodySmall` (11–12px)
- `priceMain`, `priceStrike`, `discountBadge`

**Lý do:** Hiện mỗi screen tự define text styles inline → inconsistent font sizes.

---

## Phase 2: HomeScreen Overhaul 🏠
>
> **Priority:** P0  
> **Estimated effort:** Medium  
> **Files:** `lib/screens/home_screen.dart`, `lib/widgets/product_card.dart`

### Task 2.1: Banner Carousel thay thế single static banner

**Hiện tại:** 1 static banner hardcoded "Miễn phí ship từ 150K"  
**Cải thiện:**

- `PageView.builder` với 2–3 promo banners (có thể hardcoded hoặc từ config)
- `SmoothPageIndicator` dots ở bottom  
- Auto-scroll mỗi 4s bằng `Timer.periodic`
- Mỗi banner có gradient khác nhau (emerald, amber, blue)

**Dependencies:** Thêm package `smooth_page_indicator`

### Task 2.2: Category chips — thêm icon + animation tốt hơn

**Hiện tại:** Chỉ text chips, height 44px  
**Cải thiện:**

- Thêm category icon/emoji trước text (từ category image nếu có, hoặc fallback emoji)
- AnimatedSwitcher cho text color transition
- Thêm subtle scale animation khi selected
- Tăng height lên 48px, padding comfortable hơn

### Task 2.3: Section Headers với "Xem tất cả" action

**Hiện tại:** "Sản phẩm nổi bật" + count text thẳng hàng  
**Cải thiện:**

- Section title với bold style + subtle icon
- "Xem tất cả →" link bên phải (navigate to Categories tab)
- Add spacing/divider giữa categories chips và product grid

### Task 2.4: Nâng cấp AppBar với greeting animation

**Hiện tại:** Static greeting text  
**Cải thiện:**

- Wave emoji animation khi lần đầu load
- Search transition: smooth expand animation thay vì hard switch
- Cart badge: thêm scale bounce animation khi count tăng

### Task 2.5: Empty state & error state cho product grid

**Hiện tại:** Chỉ có skeleton loading, không handle empty/error  
**Cải thiện:**

- Empty state: Illustration + "Không tìm thấy sản phẩm" + CTA button
- Error state: Retry button + friendly message
- No internet state: Offline icon + message

---

## Phase 3: ProductDetailScreen Enhancement 🛍️
>
> **Priority:** P0  
> **Estimated effort:** Medium  
> **File:** `lib/screens/product_detail_screen.dart`

### Task 3.1: Image Gallery (nếu nhiều ảnh) hoặc polish single image

**Hiện tại:** Single image trong SliverAppBar  
**Cải thiện:**

- Pinch-to-zoom bằng `InteractiveViewer`
- Image placeholder tốt hơn (shimmer thay vì CircularProgressIndicator)
- Gradient overlay ở bottom image để text readable hơn
- Share button cạnh wishlist heart

### Task 3.2: Redesign price section với visual hierarchy rõ ràng hơn

**Hiện tại:** Price, compare price, discount badge nằm một row  
**Cải thiện:**

- Price nổi bật hơn với larger size (28px)
- Savings badge: "Tiết kiệm 25,000₫" thay vì chỉ "-%"
- Unit price context: "/ kg", "/ chai" etc.

### Task 3.3: Quantity selector — haptic feedback + visual polish

**Hiện tại:** Basic +/- buttons  
**Cải thiện:**

- Haptic feedback (HapticFeedback.lightImpact)
- Animated number transition khi tăng/giảm
- Max quantity warning toast
- Total preview: "Tổng: 150,000₫" (price × quantity) cập nhật realtime

### Task 3.4: Bottom sticky "Add to Cart" bar

**Hiện tại:** Button nằm trong scroll content → bị trôi  
**Cải thiện:**

- Tách button ra khỏi scroll → fixed bottom bar
- Hiển thị price summary trên bar
- Glassmorphism effect cho bottom bar
- Cart icon với count badge hiện tại

### Task 3.5: Product info sections collapsible

**Hiện tại:** Description text thẳng  
**Cải thiện:**

- "Mô tả" section expandable nếu text dài (>3 lines → "Xem thêm")
- Thêm "Thông tin chi tiết" section (unit, category, stock)
- Subtle dividers giữa sections

---

## Phase 4: Polish Remaining Screens ✨
>
> **Priority:** P1  
> **Estimated effort:** Medium

### Task 4.1: CartScreen improvements

**File:** `lib/screens/cart_screen.dart`

- Swipe-to-delete bằng `Dismissible` widget
- Better quantity stepper (matching product detail style)
- Shipping progress bar animated (LinearProgressIndicator)
- Empty cart: animated illustration thay vì static icon

### Task 4.2: CategoriesScreen decomposition

**File:** `lib/screens/categories_screen.dart` (477 lines → target ~200)

- Extract `_buildSidebar` → `widgets/category_sidebar.dart`
- Extract `_buildProductItem` → reuse `ProductCard` widget hoặc new `CompactProductCard`
- Add staggered animation cho product items
- Shimmer skeleton cho products loading

### Task 4.3: ProfileScreen micro-polish

**File:** `lib/screens/profile_screen.dart`

- Avatar: gradient border animation khi load
- Menu items: subtle slide-in animation staggered
- Version info ở bottom: "TạpHóa v1.0.0"

### Task 4.4: Auth screens (Login, Register, Forgot Password) consistency

**Files:** `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`

- Keyboard-aware: `resizeToAvoidBottomInset` + auto scroll
- Form validation UX: real-time validation (onChange) thay vì chỉ onSubmit
- Unified top branding section (logo + tagline) → extract widget
- Remove demo accounts box (production-ready)

### Task 4.5: OrderHistoryScreen & OrderDetailScreen polish

**Files:** `order_history_screen.dart`, `order_detail_screen.dart`

- Order status timeline visualization (vertical dots + lines)
- Status colors consistent với design system
- Pull-to-refresh verification
- Order detail: grouped sections (items, shipping, payment, timeline)

### Task 4.6: NotificationsScreen polish

**File:** `notifications_screen.dart`

- Unread indicator (left color bar hoặc tinted background)
- Read/unread transition animation
- Group by date (Hôm nay, Hôm qua, Tuần này...)
- Swipe to mark as read

### Task 4.7: WishlistScreen polish

**File:** `wishlist_screen.dart`

- Grid/List view toggle
- Remove animation (scale down + fade out)
- Empty state matching design system
- Quick add to cart from wishlist

---

## Phase 5: Branding & Splash 🎨
>
> **Priority:** P1  
> **Estimated effort:** Small

### Task 5.1: Custom App Icon

- Tạo app icon cho TạpHóa (shopping bag / storefront icon)
- Dùng `flutter_launcher_icons` package
- Adaptive icon cho Android (foreground + background layers)
- iOS icon (rounded corners handled by OS)

### Task 5.2: Enhanced Splash Screen

**File:** `lib/screens/splash_screen.dart`

- Custom Lottie hoặc coded animation thay vì basic fade
- Progress indicator: indeterminate bar thay vì spinner
- Tagline animated text

### Task 5.3: Production cleanup

- Remove demo accounts từ login screen
- Update app name: "TạpHóa" thay vì "tap_hoa_app"  
- Update version string: 1.1.0

---

## Phase 6: Structural Refactoring 🏗️
>
> **Priority:** P2  
> **Estimated effort:** Medium

### Task 6.1: Screen decomposition

| File | Lines | Target | Strategy |
|------|-------|--------|----------|
| `checkout_screen.dart` | 436 | ~250 | Extract `AddressSelector`, `PaymentOptions`, `BankInfo`, `OrderSummary` widgets |
| `categories_screen.dart` | 477 | ~200 | Extract `CategorySidebar`, `CategoryProductGrid` widgets |

### Task 6.2: Shared widgets extraction

- `QuantityStepper` widget (used in Cart + Product Detail)
- `SectionHeader` widget (used in Home, Checkout, Product Detail)
- `EmptyStateWidget` (used in Cart, Wishlist, Orders, Notifications)
- `PriceDisplay` widget (used in ProductCard, ProductDetail, Cart)

### Task 6.3: Product pagination implementation

**File:** `lib/providers/product_provider.dart`

- Implement offset-based pagination (page_size=20)
- `loadMore()` method với `NotificationListener<ScrollNotification>`
- Loading more indicator ở bottom grid
- "Đã hiển thị tất cả" end message

---

## Phase 7: Performance & Polish 🚀
>
> **Priority:** P2  
> **Estimated effort:** Small

### Task 7.1: Image optimization

- `CachedNetworkImage` → thêm `memCacheWidth` / `memCacheHeight` cho thumbnails
- Placeholder shimmer thống nhất thay vì mix CircularProgressIndicator + shimmer

### Task 7.2: Animation review

- Kiểm tra animation duration consistency (hiện dùng 200ms, 300ms, 400ms, 500ms lung tung)
- Standard: 200ms cho micro (button state), 300ms cho transitions, 500ms cho entrance
- Disable heavy animations trên low-end devices

### Task 7.3: Provider optimization

- Audit `context.watch()` vs `context.read()` usage
- Replace unnecessary watches với `Consumer` targeted rebuilds
- Add `Selector` cho partial rebuilds where needed

---

## 📊 Priority Matrix

```
         IMPACT
    HIGH ┤ Phase 2 ●     Phase 3 ●
         │
    MED  ┤ Phase 1 ●     Phase 4 ●    Phase 5 ●
         │
    LOW  ┤                Phase 6 ●    Phase 7 ●
         └──────────────────────────────────────
              LOW          MED          HIGH
                        EFFORT
```

## 🔄 Execution Order

```
Phase 1 (Design tokens)
  └─→ Phase 2 (Home) ──┐
  └─→ Phase 3 (Detail) ─┤
                         ├─→ Phase 4 (Other screens)
                         │     └─→ Phase 6 (Refactoring)
                         │
                         └─→ Phase 5 (Branding)
                               └─→ Phase 7 (Performance)
```

## ✅ Verification Checklist

- [ ] All customer screens use `AppColors`, `AppSpacing`, `AppTextStyles` (no hardcoded values)
- [ ] HomeScreen: banner carousel working, category chips with icons, staggered grid
- [ ] ProductDetail: sticky bottom bar, zoom, haptic feedback
- [ ] Cart: swipe-to-delete, animated shipping progress
- [ ] No `CircularProgressIndicator` remaining (all replaced with shimmer)
- [ ] Custom app icon visible on both iOS & Android
- [ ] Splash screen with custom animation
- [ ] `CheckoutScreen` < 300 lines after decomposition
- [ ] `CategoriesScreen` < 250 lines after decomposition
- [ ] No demo accounts on login screen
- [ ] All animations follow standard durations (200/300/500ms)
- [ ] `flutter analyze` — 0 warnings
- [ ] Hot restart works without errors

---

## 📦 New Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `smooth_page_indicator` | ^1.2.0 | Banner carousel dots |
| `flutter_launcher_icons` | ^0.14.3 | Custom app icon generation |

## 📁 New Files

| File | Purpose |
|------|---------|
| `lib/constants/app_spacing.dart` | Spacing + radius tokens |
| `lib/constants/app_text_styles.dart` | Centralized text styles |
| `lib/widgets/quantity_stepper.dart` | Shared +/- counter |
| `lib/widgets/section_header.dart` | Reusable section title |
| `lib/widgets/empty_state.dart` | Unified empty/error states |
| `lib/widgets/price_display.dart` | Price formatting widget |
| `lib/widgets/category_sidebar.dart` | Extracted from categories screen |
| `lib/widgets/compact_product_card.dart` | Category grid product item |
| `assets/app_icon.png` | Custom app icon source |

---

> **Next:** Run `/create` to start implementation, or modify plan manually.
