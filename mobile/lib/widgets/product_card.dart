import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../utils/app_formatter.dart';
import '../utils/cart_toast_helper.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final Future<bool> Function()? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAdding = false;
  bool _isPressed = false;

  Future<void> _handleAddToCart() async {
    if (_isAdding || widget.onAddToCart == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isAdding = true);
    final success = await widget.onAddToCart!();
    if (mounted) {
      setState(() => _isAdding = false);
      CartToastHelper.show(context, success: success, productName: widget.product.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlist = context.watch<WishlistProvider>();
    final isWished = wishlist.isInWishlist(product.id);
    final outOfStock = product.stockQuantity <= 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.02 : 0.05),
                blurRadius: _isPressed ? 6 : 12,
                offset: Offset(0, _isPressed ? 1 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // === IMAGE ===
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'product_${product.id}',
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.shimmerBase,
                                  child: Center(
                                    child: Icon(Icons.image_outlined, color: AppColors.textLight.withValues(alpha: 0.3), size: 32),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceLight,
                                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textLight, size: 32),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceLight,
                                child: Icon(Icons.image_outlined, color: AppColors.textLight.withValues(alpha: 0.4), size: 36),
                              ),
                      ),

                      // Out of stock overlay
                      if (outOfStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Hết hàng',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error),
                            ),
                          ),
                        ),

                      // Discount badge — top left
                      if (product.discountPercent > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1.2),
                            ),
                          ),
                        ),

                      // Wishlist heart — top right, 44px hit area
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            wishlist.toggleWishlist(product);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isWished
                                    ? Colors.white
                                    : Colors.black.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isWished ? AppColors.accent : Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // === INFO ===
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top: Category + Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.categoryName != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  product.categoryName!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryStart.withValues(alpha: 0.7),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),

                        // Bottom: Price + Add to cart
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          AppFormatter.currency(product.sellingPrice),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.priceColor,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '/${product.unit}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (product.isOnSale)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Text(
                                        AppFormatter.currency(product.price),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textLight,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: AppColors.textLight,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Add to cart — 44px hit area
                            if (widget.onAddToCart != null && !outOfStock)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _handleAddToCart,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _isAdding ? AppColors.success : AppColors.primaryStart,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
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
        ),
      ),
    );
  }
}
