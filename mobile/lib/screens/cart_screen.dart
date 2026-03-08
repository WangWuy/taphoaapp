import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../providers/config_provider.dart';
import '../utils/app_formatter.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = context.read<ConfigProvider>();
      if (!config.isLoaded) config.loadConfig();
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final configProvider = context.watch<ConfigProvider>();

    final double shippingFee = configProvider.calculateShippingFee(cartProvider.totalPrice);
    final bool isFreeShip = shippingFee == 0;
    final double freeShipThreshold = configProvider.freeShipThreshold;
    final double actualShipping = cartProvider.items.isEmpty ? 0 : shippingFee;
    final double grandTotal = cartProvider.totalPrice + actualShipping;
    final double progress = freeShipThreshold > 0
        ? (cartProvider.totalPrice / freeShipThreshold).clamp(0.0, 1.0)
        : 1.0;

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
          'Giỏ hàng (${cartProvider.totalItemsCount})',
          style: AppTextStyles.headlineMedium,
        ),
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
          ? EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Giỏ hàng trống',
              subtitle: 'Hãy thêm sản phẩm vào giỏ hàng để bắt đầu mua sắm',
              actionText: 'Khám phá sản phẩm',
              onAction: () => Navigator.pop(context),
            )
          : Column(
              children: [
                // Shipping progress bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isFreeShip ? AppColors.successLight : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFreeShip
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFreeShip ? Icons.local_shipping_rounded : Icons.info_outline_rounded,
                            color: isFreeShip ? AppColors.success : AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFreeShip
                                  ? '🎉 Bạn được miễn phí giao hàng!'
                                  : 'Mua thêm ${AppFormatter.currency(freeShipThreshold - cartProvider.totalPrice)} để miễn phí ship',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isFreeShip ? AppColors.success : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isFreeShip) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          HapticFeedback.mediumImpact();
                          cartProvider.removeFromCart(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã xóa ${item.product.name}'),
                              backgroundColor: AppColors.textSecondary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                              SizedBox(height: 2),
                              Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: item.product),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.product.imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: item.product.imageUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(width: 80, height: 80, color: AppColors.surfaceLight),
                                          errorWidget: (_, __, ___) => Container(
                                            width: 80, height: 80,
                                            color: AppColors.surfaceLight,
                                            child: const Icon(Icons.image_outlined, color: AppColors.textLight),
                                          ),
                                        )
                                      : Container(
                                          width: 80, height: 80,
                                          color: AppColors.surfaceLight,
                                          child: const Icon(Icons.image_outlined, color: AppColors.textLight),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: item.product),
                                      child: Text(
                                        item.product.name,
                                        style: AppTextStyles.labelLarge,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${AppFormatter.currency(item.product.sellingPrice)}/${item.product.unit}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.primaryStart, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildQtyButton(Icons.remove_rounded, () {
                                          HapticFeedback.lightImpact();
                                          if (item.quantity > 1) {
                                            cartProvider.updateQuantity(item.id, item.quantity - 1);
                                          } else {
                                            cartProvider.removeFromCart(item.id);
                                          }
                                        }),
                                        Container(
                                          width: 40,
                                          alignment: Alignment.center,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                            child: Text(
                                              '${item.quantity}',
                                              key: ValueKey(item.quantity),
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                        _buildQtyButton(Icons.add_rounded, () {
                                          HapticFeedback.lightImpact();
                                          cartProvider.updateQuantity(item.id, item.quantity + 1);
                                        }),
                                        const Spacer(),
                                        Text(
                                          AppFormatter.currency(item.subtotal),
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 80 * index), duration: 300.ms),
                      );
                    },
                  ),
                ),

                // Bottom summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: AppColors.bottomBarShadow,
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildSummaryRow('Tạm tính:', AppFormatter.currency(cartProvider.totalPrice)),
                        const SizedBox(height: 6),
                        _buildSummaryRow(
                          'Phí giao hàng:',
                          isFreeShip ? 'Miễn phí' : AppFormatter.currency(actualShipping),
                          valueColor: isFreeShip ? AppColors.success : null,
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AppColors.divider)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tổng cộng:', style: AppTextStyles.headlineSmall),
                            Text(
                              AppFormatter.currency(grandTotal),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryStart),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Tiến hành đặt hàng',
                          onPressed: () => Navigator.pushNamed(context, '/checkout'),
                          icon: Icons.payment_rounded,
                        ),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa giỏ hàng?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa hết', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
