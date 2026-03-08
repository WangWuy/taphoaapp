import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final stats = orderProvider.dashboardStats;
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xin chào, ${authProvider.currentUser?.name ?? 'Admin'} 👋', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        const Text('Quản lý TạpHóa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(children: [Icon(Icons.logout_rounded, size: 20, color: AppColors.error), SizedBox(width: 8), Text('Đăng xuất', style: TextStyle(color: AppColors.error))]),
                        onTap: () {
                          context.read<AuthProvider>().logout();
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('Đơn hàng', '${stats?['totalOrders'] ?? 0}', Icons.receipt_long_rounded, const Color(0xFF3B82F6), 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Chờ xử lý', '${stats?['pendingOrders'] ?? 0}', Icons.hourglass_top_rounded, const Color(0xFFF59E0B), 1)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Khách hàng', '${stats?['totalCustomers'] ?? 0}', Icons.people_rounded, const Color(0xFF8B5CF6), 2)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Doanh thu', '${currencyFormat.format(stats?['totalRevenue'] ?? 0)}₫', Icons.attach_money_rounded, const Color(0xFF059669), 3)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Sắp hết hàng', '${stats?['lowStockProducts'] ?? 0}', Icons.warning_amber_rounded, const Color(0xFFEF4444), 4)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Sản phẩm', '${stats?['totalProducts'] ?? 0}', Icons.inventory_2_rounded, const Color(0xFF0EA5E9), 5)),
                ],
              ),
              const SizedBox(height: 28),

              // Menu
              const Text('Quản lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              _buildMenuItem(Icons.receipt_long_rounded, 'Quản lý đơn hàng', 'Xem, xác nhận, cập nhật trạng thái', () => Navigator.pushNamed(context, '/admin-orders'), const Color(0xFF3B82F6)),
              const SizedBox(height: 10),
              _buildMenuItem(Icons.inventory_2_rounded, 'Quản lý sản phẩm', 'Thêm, sửa, xóa sản phẩm', () => Navigator.pushNamed(context, '/admin-products'), const Color(0xFF059669)),
              const SizedBox(height: 10),
              _buildMenuItem(Icons.category_rounded, 'Quản lý danh mục', 'Thêm, sửa, xóa danh mục', () => Navigator.pushNamed(context, '/admin-categories'), const Color(0xFFF59E0B)),
              const SizedBox(height: 10),
              _buildMenuItem(Icons.people_rounded, 'Danh sách khách hàng', 'Xem thông tin & địa chỉ khách', () => Navigator.pushNamed(context, '/admin-customers'), const Color(0xFF8B5CF6)),
              const SizedBox(height: 10),
              _buildMenuItem(Icons.bar_chart_rounded, 'Thống kê & Báo cáo', 'Doanh thu, top sản phẩm, tồn kho', () => Navigator.pushNamed(context, '/admin-dashboard'), const Color(0xFFEC4899)),
              const SizedBox(height: 10),
              _buildMenuItem(Icons.settings_rounded, 'Cài đặt cửa hàng', 'Ngân hàng, phí ship, thông tin', () => Navigator.pushNamed(context, '/admin-config'), const Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
