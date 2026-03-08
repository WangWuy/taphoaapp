import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../utils/app_formatter.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    final wishlist = context.watch<WishlistProvider>();
    final cartProvider = context.watch<CartProvider>();
    final isWished = wishlist.isInWishlist(product.id);
    final totalPrice = product.sellingPrice * _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Image header
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.40,
                  pinned: true,
                  backgroundColor: AppColors.cardBackground,
                  leading: _buildCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  actions: [
                    _buildCircleButton(
                      icon: isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      iconColor: isWished ? AppColors.error : AppColors.textPrimary,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        wishlist.toggleWishlist(product);
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'product_${product.id}',
                          child: product.imageUrl != null
                              ? InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 3.0,
                                  child: CachedNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceLight,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(color: AppColors.primaryStart, strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.image_not_supported_rounded, size: 60, color: AppColors.textLight),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.surfaceLight,
                                  child: const Icon(Icons.image_outlined, size: 60, color: AppColors.textLight),
                                ),
                        ),
                        // Bottom gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Discount badge on image
                        if (product.discountPercent > 0)
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '-${product.discountPercent}%',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Product info
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & Unit row
                          Row(
                            children: [
                              if (product.categoryName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryStart.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.categoryName!,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryStart),
                                  ),
                                ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '📦 ${product.unit}',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),

                          const SizedBox(height: 14),

                          // Product name
                          Text(
                            product.name,
                            style: AppTextStyles.headlineLarge,
                          ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),

                          const SizedBox(height: 14),

                          // Price section
                          _buildPriceSection(product)
                              .animate().fadeIn(delay: 160.ms, duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),

                          const SizedBox(height: 16),

                          // Stock status
                          _buildStockStatus(product)
                              .animate().fadeIn(delay: 240.ms, duration: 300.ms),

                          const SizedBox(height: 20),
                          const Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 16),

                          // Description
                          _buildDescriptionSection(product)
                              .animate().fadeIn(delay: 320.ms, duration: 300.ms),

                          const SizedBox(height: 20),
                          const Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 16),

                          // Quantity selector
                          _buildQuantitySelector(product)
                              .animate().fadeIn(delay: 400.ms, duration: 300.ms),

                          // Total price preview
                          if (_quantity > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Tổng: ', style: AppTextStyles.bodyMedium),
                                  Text(
                                    AppFormatter.currency(totalPrice),
                                    style: AppTextStyles.priceMain.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 200.ms),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky bottom bar
          _buildBottomBar(product, cartProvider, totalPrice),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatter.currency(product.sellingPrice),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.priceColor),
            ),
            Text(
              ' / ${product.unit}',
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
            ),
          ],
        ),
        if (product.isOnSale) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                AppFormatter.currency(product.price),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.originalPriceColor,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tiết kiệm ${AppFormatter.currency(product.price - product.compareAtPrice!)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStockStatus(Product product) {
    final inStock = product.stockQuantity > 0;
    final isLow = product.stockQuantity > 0 && product.stockQuantity <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: inStock ? (isLow ? AppColors.warningLight : AppColors.successLight) : AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: inStock ? (isLow ? AppColors.warning : AppColors.success) : AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            inStock
                ? (isLow ? 'Chỉ còn ${product.stockQuantity} sản phẩm' : 'Còn ${product.stockQuantity} sản phẩm')
                : 'Hết hàng',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: inStock ? (isLow ? AppColors.warning : AppColors.success) : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(Product product) {
    final description = product.description ?? 'Sản phẩm chất lượng cao, giá tốt nhất.';
    final isLong = description.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mô tả sản phẩm', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          firstChild: Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7),
          ),
          secondChild: Text(
            description,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7),
          ),
          crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _descExpanded ? 'Thu gọn' : 'Xem thêm',
                style: AppTextStyles.sectionAction,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantitySelector(Product product) {
    return Row(
      children: [
        Text('Số lượng', style: AppTextStyles.headlineSmall),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildQtyButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_quantity > 1) {
                    HapticFeedback.lightImpact();
                    setState(() => _quantity--);
                  }
                },
                enabled: _quantity > 1,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 52),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Text(
                    '$_quantity',
                    key: ValueKey(_quantity),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              ),
              _buildQtyButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_quantity < product.stockQuantity) {
                    HapticFeedback.lightImpact();
                    setState(() => _quantity++);
                  } else {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đã đạt số lượng tối đa trong kho'),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                enabled: _quantity < product.stockQuantity,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Product product, CartProvider cartProvider, double totalPrice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: AppColors.bottomBarShadow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tổng tiền', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatter.currency(totalPrice),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.priceColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Add to cart button
            Expanded(
              child: GestureDetector(
                onTap: product.stockQuantity > 0 && !_isAdding
                    ? () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _isAdding = true);
                        final success = await context.read<CartProvider>().addToCart(product.id, quantity: _quantity);
                        if (mounted) setState(() => _isAdding = false);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Xem giỏ',
                                textColor: Colors.white,
                                onPressed: () => Navigator.pushNamed(context, '/cart'),
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: product.stockQuantity > 0
                        ? (_isAdding ? null : AppColors.primaryGradient)
                        : null,
                    color: product.stockQuantity > 0
                        ? (_isAdding ? AppColors.success : null)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: product.stockQuantity > 0 ? AppColors.buttonShadow : null,
                  ),
                  child: Center(
                    child: _isAdding
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Text('Đã thêm!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                color: product.stockQuantity > 0 ? Colors.white : AppColors.textLight,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product.stockQuantity > 0 ? 'Thêm vào giỏ' : 'Hết hàng',
                                style: TextStyle(
                                  color: product.stockQuantity > 0 ? Colors.white : AppColors.textLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.3, end: 0, duration: 400.ms);
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.overlayLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textPrimary : AppColors.textLight,
        ),
      ),
    );
  }
}
