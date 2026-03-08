import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    const double freeShipThreshold = 150000;
    const double shippingFee = 10000;
    final bool isFreeShip = cartProvider.totalPrice >= freeShipThreshold;
    final double actualShipping = cartProvider.items.isEmpty ? 0 : (isFreeShip ? 0 : shippingFee);
    final double grandTotal = cartProvider.totalPrice + actualShipping;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Giỏ hàng (${cartProvider.totalItemsCount})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (cartProvider.items.isNotEmpty)
            TextButton(
              onPressed: () => _showClearCartDialog(context, cartProvider),
              child: const Text('Xóa hết', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: cartProvider.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Giỏ hàng trống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Hãy thêm sản phẩm vào giỏ hàng', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                ],
              ),
            )
          : Column(
              children: [
                // Shipping progress bar
                if (cartProvider.items.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFreeShip ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isFreeShip ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(isFreeShip ? Icons.local_shipping_rounded : Icons.info_outline_rounded, color: isFreeShip ? const Color(0xFF059669) : const Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isFreeShip ? '🎉 Bạn được miễn phí giao hàng!' : 'Mua thêm ${currencyFormat.format(freeShipThreshold - cartProvider.totalPrice)}₫ để miễn phí ship',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isFreeShip ? const Color(0xFF059669) : const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: item.product),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.product.imageUrl != null
                                    ? CachedNetworkImage(imageUrl: item.product.imageUrl!, width: 80, height: 80, fit: BoxFit.cover, placeholder: (_, __) => Container(width: 80, height: 80, color: AppColors.surfaceLight), errorWidget: (_, __, ___) => Container(width: 80, height: 80, color: AppColors.surfaceLight, child: const Icon(Icons.image_outlined)))
                                    : Container(width: 80, height: 80, color: AppColors.surfaceLight, child: const Icon(Icons.image_outlined, color: AppColors.textLight)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: item.product),
                                    child: Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${currencyFormat.format(item.product.price)}₫/${item.product.unit}', style: const TextStyle(fontSize: 13, color: AppColors.primaryStart, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildQtyButton(Icons.remove, () {
                                        if (item.quantity > 1) {
                                          cartProvider.updateQuantity(item.id, item.quantity - 1);
                                        } else {
                                          cartProvider.removeFromCart(item.id);
                                        }
                                      }),
                                      Container(width: 40, alignment: Alignment.center, child: Text('${item.quantity}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                      _buildQtyButton(Icons.add, () => cartProvider.updateQuantity(item.id, item.quantity + 1)),
                                      const Spacer(),
                                      Text('${currencyFormat.format(item.subtotal)}₫', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms);
                    },
                  ),
                ),

                // Bottom summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            Text('${currencyFormat.format(cartProvider.totalPrice)}₫', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phí giao hàng:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            Text(isFreeShip ? 'Miễn phí' : '${currencyFormat.format(actualShipping)}₫', style: TextStyle(fontSize: 14, color: isFreeShip ? const Color(0xFF059669) : AppColors.textPrimary, fontWeight: isFreeShip ? FontWeight.w600 : FontWeight.w400)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('${currencyFormat.format(grandTotal)}₫', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryStart)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CustomButton(text: 'Tiến hành đặt hàng', onPressed: () => Navigator.pushNamed(context, '/checkout'), icon: Icons.payment_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa giỏ hàng?'),
        content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ hàng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa hết', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
