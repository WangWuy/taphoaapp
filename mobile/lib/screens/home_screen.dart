import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:badges/badges.dart' as badges;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _bannerController = PageController();
  bool _isSearching = false;
  Timer? _debounce;
  Timer? _bannerTimer;
  int _currentBanner = 0;

  final List<_BannerData> _banners = [
    _BannerData(
      title: 'Miễn phí ship từ 150K',
      subtitle: 'Hàng tiêu dùng, thực phẩm & gia vị',
      badge: '🛒 Khuyến mãi hôm nay',
      gradient: AppColors.bannerEmerald,
      icon: Icons.local_shipping_rounded,
    ),
    _BannerData(
      title: 'Giảm giá đến 30%',
      subtitle: 'Sản phẩm chọn lọc mỗi ngày',
      badge: '🔥 Hot deals',
      gradient: AppColors.bannerAmber,
      icon: Icons.local_fire_department_rounded,
    ),
    _BannerData(
      title: 'Giao nhanh 2h',
      subtitle: 'Nội thành — đặt ngay, nhận liền',
      badge: '⚡ Siêu tốc',
      gradient: AppColors.bannerBlue,
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CartProvider>().loadCart();
    });
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        _currentBanner = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _debounce?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(authProvider, cartProvider),
            Expanded(
              child: productProvider.isLoading
                  ? const SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          ProductGridSkeleton(count: 6),
                        ],
                      ),
                    )
                  : productProvider.error != null
                      ? EmptyStateWidget(
                          icon: Icons.wifi_off_rounded,
                          title: 'Không thể tải sản phẩm',
                          subtitle: productProvider.error,
                          actionText: 'Thử lại',
                          onAction: () => productProvider.loadProducts(refresh: true),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                                !productProvider.isLoadingMore && productProvider.hasMore) {
                              productProvider.loadMore();
                            }
                            return false;
                          },
                          child: RefreshIndicator(
                            color: AppColors.primaryStart,
                            onRefresh: () => productProvider.loadProducts(refresh: true),
                            child: CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(child: _buildBannerCarousel()),
                                SliverToBoxAdapter(child: _buildCategories(productProvider)),
                                SliverToBoxAdapter(
                                  child: SectionHeader(
                                    title: productProvider.selectedCategoryId == null
                                        ? 'Sản phẩm nổi bật'
                                        : productProvider.selectedCategoryName,
                                    actionText: 'Xem tất cả',
                                    onAction: () {
                                      TabSwitchNotification(1).dispatch(context);
                                    },
                                  ),
                                ),
                                // Product grid or empty state
                                if (productProvider.products.isEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: EmptyStateWidget(
                                      icon: Icons.inventory_2_outlined,
                                      title: 'Không tìm thấy sản phẩm',
                                      subtitle: 'Thử tìm với từ khóa khác',
                                      actionText: 'Xem tất cả',
                                      onAction: () {
                                        _searchController.clear();
                                        productProvider.searchProducts('');
                                        setState(() => _isSearching = false);
                                      },
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: AnimationLimiter(
                                      child: SliverGrid(
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 14,
                                          crossAxisSpacing: 14,
                                          childAspectRatio: 0.62,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final product = productProvider.products[index];
                                            return AnimationConfiguration.staggeredGrid(
                                              position: index,
                                              duration: const Duration(milliseconds: 400),
                                              columnCount: 2,
                                              child: ScaleAnimation(
                                                child: FadeInAnimation(
                                                  child: ProductCard(
                                                    product: product,
                                                    onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
                                                    onAddToCart: () {
                                                      context.read<CartProvider>().addToCart(product.id);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: [
                                                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  'Đã thêm ${product.name} vào giỏ',
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          backgroundColor: AppColors.success,
                                                          behavior: SnackBarBehavior.floating,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          duration: const Duration(milliseconds: 1400),
                                                          action: SnackBarAction(
                                                            label: 'Xem giỏ',
                                                            textColor: Colors.white,
                                                            onPressed: () => Navigator.pushNamed(context, '/cart'),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          childCount: productProvider.products.length,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Load more indicator
                                if (productProvider.isLoadingMore)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryStart, strokeWidth: 2)),
                                    ),
                                  ),
                                if (!productProvider.hasMore && productProvider.products.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceLight,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            '✨ Đã hiển thị tất cả sản phẩm',
                                            style: TextStyle(fontSize: 13, color: AppColors.textLight),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!_isSearching) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, ${authProvider.currentUser?.name ?? 'Bạn'} 👋',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'TạpHóa Shop',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            _buildIconButton(
              icon: Icons.search_rounded,
              onTap: () => setState(() => _isSearching = true),
            ),
          ] else ...[
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 22),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textLight, size: 22),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ProductProvider>().searchProducts('');
                        setState(() => _isSearching = false);
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      context.read<ProductProvider>().searchProducts(value);
                    });
                  },
                ),
              ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1, end: 0, duration: 200.ms),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: badges.Badge(
              showBadge: cartProvider.totalItemsCount > 0,
              badgeContent: Text(
                '${cartProvider.totalItemsCount}',
                style: AppTextStyles.badgeText,
              ),
              badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent, padding: EdgeInsets.all(5)),
              child: _buildIconButton(
                icon: Icons.shopping_cart_outlined,
                onTap: () => Navigator.pushNamed(context, '/cart'),
                isRaw: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, bool isRaw = false}) {
    final child = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 22),
    );
    if (isRaw) return child;
    return GestureDetector(onTap: onTap, child: child);
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBanner = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: banner.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: banner.gradient.first.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              banner.badge,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            banner.title,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Icon
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(banner.icon, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
        const SizedBox(height: 12),
        // Page indicator
        SmoothPageIndicator(
          controller: _bannerController,
          count: _banners.length,
          effect: ExpandingDotsEffect(
            activeDotColor: AppColors.primaryStart,
            dotColor: AppColors.divider,
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3,
            spacing: 6,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategories(ProductProvider productProvider) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: productProvider.categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final categoryId = isAll ? null : productProvider.categories[index - 1].id;
          final name = isAll ? 'Tất cả' : productProvider.categories[index - 1].name;
          final isSelected = productProvider.selectedCategoryId == categoryId;

          return GestureDetector(
            onTap: () => productProvider.filterByCategory(categoryId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primaryStart.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                child: Text(name),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> gradient;
  final IconData icon;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradient,
    required this.icon,
  });
}
