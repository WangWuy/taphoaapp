import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:badges/badges.dart' as badges;
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
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
                            SliverToBoxAdapter(child: _buildBanner()),
                            SliverToBoxAdapter(child: _buildCategories(productProvider)),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      productProvider.selectedCategoryId == null ? 'Sản phẩm nổi bật' : productProvider.selectedCategoryName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text('${productProvider.products.length} sản phẩm', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: AnimationLimiter(
                                child: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.62),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final product = productProvider.products[index];
                                      return AnimationConfiguration.staggeredGrid(
                                        position: index,
                                        duration: const Duration(milliseconds: 400),
                                        columnCount: 2,
                                        child: ScaleAnimation(child: FadeInAnimation(child: ProductCard(
                                          product: product,
                                          onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
                                          onAddToCart: () {
                                            context.read<CartProvider>().addToCart(product.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Đã thêm ${product.name} vào giỏ'),
                                                backgroundColor: const Color(0xFF059669),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                duration: const Duration(milliseconds: 1200),
                                              ),
                                            );
                                          },
                                        ))),
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
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: Text('Đã hiển thị tất cả sản phẩm', style: TextStyle(fontSize: 13, color: AppColors.textLight))),
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
                  Text('Xin chào, ${authProvider.currentUser?.name ?? 'Bạn'} 👋', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  const Text('TạpHóa Shop', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
            ),
            IconButton(onPressed: () => setState(() => _isSearching = true), icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 26)),
          ] else ...[
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14)),
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
              ),
            ),
          ],
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: badges.Badge(
              showBadge: cartProvider.totalItemsCount > 0,
              badgeContent: Text('${cartProvider.totalItemsCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent, padding: EdgeInsets.all(5)),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
          Positioned(right: 30, bottom: -30, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('🛒 Khuyến mãi hôm nay', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                const Text('Miễn phí ship từ 150K', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Hàng tiêu dùng, thực phẩm & gia vị', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ],
            ),
          ),
          Positioned(
            right: 16, bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, duration: 500.ms);
  }

  Widget _buildCategories(ProductProvider productProvider) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: productProvider.categories.length + 1, // +1 for "Tất cả"
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final categoryId = isAll ? null : productProvider.categories[index - 1].id;
          final name = isAll ? 'Tất cả' : productProvider.categories[index - 1].name;
          final isSelected = productProvider.selectedCategoryId == categoryId;

          return GestureDetector(
            onTap: () => productProvider.filterByCategory(categoryId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}
