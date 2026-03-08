import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Profile header
              _buildProfileHeader(user?.name ?? 'Người dùng', user?.phone ?? '', user?.email),
              const SizedBox(height: 28),
              // Menu items
              _buildMenuSection(context, authProvider),
              const SizedBox(height: 24),
              // Version info
              Text(
                'TạpHóa v1.1.0',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String phone, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms);
  }

  Widget _buildMenuSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        _buildMenuGroup('Tài khoản', [
          _MenuItem(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Thông tin cá nhân',
            onTap: () => Navigator.pushNamed(context, '/profile-edit'),
          ),
          _MenuItem(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Đổi mật khẩu',
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),
          _MenuItem(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Địa chỉ giao hàng',
            onTap: () => Navigator.pushNamed(context, '/addresses'),
          ),
        ], 0),
        const SizedBox(height: 16),
        _buildMenuGroup('Mua sắm', [
          _MenuItem(
            icon: Icons.shopping_cart_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Giỏ hàng',
            onTap: () => Navigator.pushNamed(context, '/cart'),
          ),
          _MenuItem(
            icon: Icons.favorite_border_rounded,
            iconColor: const Color(0xFFEC4899),
            title: 'Sản phẩm yêu thích',
            onTap: () => Navigator.pushNamed(context, '/wishlist'),
          ),
        ], 1),
        const SizedBox(height: 16),
        // Admin section
        if (authProvider.isAdmin)
          ...[
            _buildMenuGroup('Quản trị', [
              _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: 'Trang quản trị',
                onTap: () => Navigator.pushNamed(context, '/admin-home'),
              ),
              _MenuItem(
                icon: Icons.settings_rounded,
                iconColor: const Color(0xFF0EA5E9),
                title: 'Cài đặt cửa hàng',
                onTap: () => Navigator.pushNamed(context, '/admin-config'),
              ),
            ], 2),
            const SizedBox(height: 16),
          ],
        // Logout
        _buildMenuGroup('Khác', [
          _MenuItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF6B7280),
            title: 'Trợ giúp & Hỗ trợ',
            onTap: () => _showHelpDialog(context),
          ),
          _MenuItem(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'Đăng xuất',
            titleColor: const Color(0xFFEF4444),
            showArrow: false,
            onTap: () => _showLogoutDialog(context, authProvider),
          ),
        ], 3),
      ],
    );
  }

  Widget _buildMenuGroup(String title, List<_MenuItem> items, int groupIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(height: 1, indent: 56, color: AppColors.surfaceLight),
                  _buildMenuTile(item),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * groupIndex), duration: 300.ms)
        .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 100 * groupIndex), duration: 300.ms);
  }

  Widget _buildMenuTile(_MenuItem item) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item.iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 20),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: item.titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: item.showArrow
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 22)
          : null,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              authProvider.logout();
              context.read<CartProvider>().clearLocal();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Trợ giúp & Hỗ trợ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _buildHelpItem(Icons.phone_rounded, 'Hotline', '0123 456 789', const Color(0xFF059669)),
            _buildHelpItem(Icons.email_rounded, 'Email', 'support@taphoa.shop', const Color(0xFF3B82F6)),
            _buildHelpItem(Icons.access_time_rounded, 'Giờ làm việc', '8:00 - 21:00 (T2 - CN)', const Color(0xFFF59E0B)),
            const SizedBox(height: 16),
            const Text('Câu hỏi thường gặp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildFaqItem('Làm sao để đặt hàng?', 'Chọn sản phẩm → Thêm vào giỏ → Đặt hàng'),
            _buildFaqItem('Thời gian giao hàng?', 'Giao trong ngày hoặc hôm sau tùy khu vực'),
            _buildFaqItem('Chính sách đổi trả?', 'Đổi trả trong 24h nếu sản phẩm lỗi'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w700)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(answer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final bool showArrow;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.showArrow = true,
    required this.onTap,
  });
}
