import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../utils/app_formatter.dart';
import '../widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    final wishlist = context.watch<WishlistProvider>();
    final isWished = wishlist.isInWishlist(product.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.42,
            pinned: true,
            backgroundColor: AppColors.cardBackground,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => wishlist.toggleWishlist(product),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Icon(
                    isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isWished ? AppColors.error : AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${product.id}',
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceLight, child: const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))),
                        errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight, child: const Icon(Icons.image_not_supported_rounded, size: 60, color: AppColors.textLight)),
                      )
                    : Container(color: AppColors.surfaceLight, child: const Icon(Icons.image_outlined, size: 60, color: AppColors.textLight)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Unit
                    Row(
                      children: [
                        if (product.categoryName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(product.categoryName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryStart)),
                          ),
                        const Spacer(),
                        Text('Đơn vị: ${product.unit}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),

                    const SizedBox(height: 12),

                    // Product name
                    Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3))
                        .animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),

                    const SizedBox(height: 12),

                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(AppFormatter.currency(product.price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.priceColor)),
                        if (product.isOnSale) ...[
                          const SizedBox(width: 10),
                          Text(AppFormatter.currency(product.compareAtPrice!), style: const TextStyle(fontSize: 16, color: AppColors.originalPriceColor, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                            child: Text('-${product.discountPercent}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),

                    const SizedBox(height: 16),

                    // Stock info
                    Row(
                      children: [
                        Icon(product.stockQuantity > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded, color: product.stockQuantity > 0 ? AppColors.success : AppColors.error, size: 18),
                        const SizedBox(width: 6),
                        Text(product.stockQuantity > 0 ? 'Còn ${product.stockQuantity} sản phẩm' : 'Hết hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: product.stockQuantity > 0 ? AppColors.success : AppColors.error)),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 20),
                    Divider(color: AppColors.surfaceLight, thickness: 1.5),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                        .animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 8),
                    Text(product.description ?? 'Sản phẩm chất lượng cao, giá tốt nhất.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6))
                        .animate().fadeIn(delay: 500.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Quantity selector
                    Row(
                      children: [
                        const Text('Số lượng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              _buildQtyButton(icon: Icons.remove, onTap: () { if (_quantity > 1) setState(() => _quantity--); }),
                              Container(constraints: const BoxConstraints(minWidth: 48), alignment: Alignment.center, child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                              _buildQtyButton(icon: Icons.add, onTap: () { if (_quantity < product.stockQuantity) setState(() => _quantity++); }),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Add to cart button
                    CustomButton(
                      text: 'Thêm vào giỏ hàng',
                      isLoading: _isAdding,
                      onPressed: product.stockQuantity > 0 ? () async {
                        setState(() => _isAdding = true);
                        final success = await context.read<CartProvider>().addToCart(product.id, quantity: _quantity);
                        if (mounted) setState(() => _isAdding = false);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20), const SizedBox(width: 8), Expanded(child: Text('Đã thêm ${product.name} vào giỏ hàng', maxLines: 1, overflow: TextOverflow.ellipsis))]),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(label: 'Xem giỏ', textColor: Colors.white, onPressed: () => Navigator.pushNamed(context, '/cart')),
                            ),
                          );
                        }
                      } : null,
                      icon: Icons.shopping_cart_outlined,
                    ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: AppColors.textPrimary)),
    );
  }
}
