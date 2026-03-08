import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/order.dart';
import '../widgets/custom_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as Order?;
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF059669), size: 56),
              ).animate().scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text('Đặt hàng thành công! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary))
                  .animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 8),
              const Text('Cảm ơn bạn đã mua hàng tại TạpHóa Shop', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))
                  .animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 8),
              if (order != null)
                Text(
                  order.paymentMethod == 'cod'
                      ? 'Bạn chỉ cần thanh toán khi nhận hàng, không cần chuyển khoản trước.'
                      : 'Vui lòng chuyển khoản theo thông tin đã cung cấp để đơn hàng được xử lý nhanh hơn.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
              const SizedBox(height: 32),
              if (order != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                  child: Column(
                    children: [
                      _buildInfoRow('Mã đơn hàng', order.orderNumber),
                      const SizedBox(height: 10),
                      _buildInfoRow('Tổng tiền', '${currencyFormat.format(order.total)}₫'),
                      const SizedBox(height: 10),
                      _buildInfoRow('Thanh toán', order.paymentMethod == 'cod' ? 'Tiền mặt (COD)' : 'Chuyển khoản'),
                      if (order.note != null && order.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow('Ghi chú', order.note!),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Xem đơn hàng',
                onPressed: () => Navigator.pushReplacementNamed(context, '/order-history'),
                icon: Icons.receipt_long_rounded,
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: const Text('Tiếp tục mua sắm', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w600)),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right)),
      ],
    );
  }
}
