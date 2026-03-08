import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yêu thích (${wishlist.count})',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: wishlist.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : wishlist.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline_rounded, size: 80, color: AppColors.textLight.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('Chưa có sản phẩm yêu thích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Nhấn ❤️ trên sản phẩm để thêm vào đây', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Khám phá sản phẩm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryStart,
                  onRefresh: () => wishlist.loadWishlist(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: wishlist.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = wishlist.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            // Product image
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: product.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: product.imageUrl!,
                                        width: 90, height: 90, fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(width: 90, height: 90, color: AppColors.surfaceLight),
                                        errorWidget: (_, __, ___) => Container(width: 90, height: 90, color: AppColors.surfaceLight, child: const Icon(Icons.image_outlined)),
                                      )
                                    : Container(width: 90, height: 90, color: AppColors.surfaceLight, child: const Icon(Icons.image_outlined, color: AppColors.textLight)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (product.isOnSale) ...[
                                    Row(
                                      children: [
                                        Text(
                                          '${currencyFormat.format(product.compareAtPrice)}₫',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textLight, decoration: TextDecoration.lineThrough),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text('-${product.discountPercent}%', style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    '${currencyFormat.format(product.price)}₫',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryStart),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Add to cart
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
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
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                                                SizedBox(width: 4),
                                                Text('Thêm vào giỏ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Remove from wishlist
                                      GestureDetector(
                                        onTap: () => wishlist.removeFromWishlist(product.id),
                                        child: Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.favorite_rounded, color: AppColors.error, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 80 * index), duration: 300.ms);
                    },
                  ),
                ),
    );
  }
}
