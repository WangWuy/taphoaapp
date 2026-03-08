import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../utils/app_formatter.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isAdding = false;

  Future<void> _handleAddToCart() async {
    if (_isAdding || widget.onAddToCart == null) return;
    setState(() => _isAdding = true);
    widget.onAddToCart!();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isWished = wishlist.isInWishlist(widget.product.id);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Hero(
                      tag: 'product_${widget.product.id}',
                      child: widget.product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.surfaceLight,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryStart)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textLight, size: 40),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.image_outlined, color: AppColors.textLight, size: 40),
                            ),
                    ),
                  ),

                  // Discount badge
                  if (widget.product.discountPercent > 0)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${widget.product.discountPercent}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),

                  // Wishlist heart button
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => wishlist.toggleWishlist(widget.product),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isWished ? AppColors.error.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWished ? AppColors.error : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppFormatter.currency(widget.product.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.priceColor)),
                              if (widget.product.isOnSale) ...[
                                const SizedBox(height: 1),
                                Text(AppFormatter.currency(widget.product.compareAtPrice!), style: const TextStyle(fontSize: 11, color: AppColors.originalPriceColor, decoration: TextDecoration.lineThrough)),
                              ],
                            ],
                          ),
                        ),
                        // Quick add to cart button
                        if (widget.onAddToCart != null)
                          GestureDetector(
                            onTap: _handleAddToCart,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: _isAdding ? null : AppColors.primaryGradient,
                                color: _isAdding ? AppColors.success : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isAdding ? AppColors.success : AppColors.primaryStart).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isAdding
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18, key: ValueKey('check'))
                                      : const Icon(Icons.add_rounded, color: Colors.white, size: 18, key: ValueKey('add')),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
