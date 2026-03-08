import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/app_formatter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: const Text(
                'Đơn hàng',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: orderProvider.isLoading
          ? const ListItemSkeleton(count: 4)
          : orderProvider.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.textLight.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Đặt hàng đầu tiên ngay nào!', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Mua sắm ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryStart,
                  onRefresh: () => orderProvider.loadOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
                      return _buildOrderCard(context, order, orderProvider, index);
                    },
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, OrderProvider orderProvider, int index) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order.id),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              _buildStatusBadge(order.status, order.statusText),
            ],
          ),
          const SizedBox(height: 8),
          Text('${order.items.length} sản phẩm', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            order.paymentMethod == 'cod' ? '💵 COD' : '🏦 Chuyển khoản',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          ...order.items.take(2).map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• ${item.productName} x${item.quantity}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          if (order.items.length > 2) Text('... và ${order.items.length - 2} sản phẩm khác', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textLight)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng:', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Text(AppFormatter.currency(order.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryStart)),
            ],
          ),
          if (order.canCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, order, orderProvider),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Hủy đơn hàng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms),
    );
  }

  Widget _buildStatusBadge(String status, String text) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'pending': bgColor = const Color(0xFFFEF3C7); textColor = const Color(0xFF92400E); break;
      case 'confirmed': bgColor = const Color(0xFFDBEAFE); textColor = const Color(0xFF1E40AF); break;
      case 'preparing': bgColor = const Color(0xFFE0E7FF); textColor = const Color(0xFF3730A3); break;
      case 'shipping': bgColor = const Color(0xFFFED7AA); textColor = const Color(0xFF9A3412); break;
      case 'delivered': bgColor = const Color(0xFFD1FAE5); textColor = const Color(0xFF065F46); break;
      case 'cancelled': bgColor = const Color(0xFFFEE2E2); textColor = const Color(0xFF991B1B); break;
      default: bgColor = AppColors.surfaceLight; textColor = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  void _confirmCancel(BuildContext context, Order order, OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đơn hàng?'),
        content: Text('Bạn có chắc muốn hủy đơn ${order.orderNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await orderProvider.cancelOrder(order.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng thành công'), backgroundColor: Color(0xFF059669)));
              }
            },
            child: const Text('Hủy đơn', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
