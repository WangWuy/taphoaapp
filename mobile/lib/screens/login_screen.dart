import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final route = authProvider.isAdmin ? '/admin-home' : '/home';
      Navigator.pushReplacementNamed(context, route);
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 36, color: Colors.white),
                ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                const Text('TạpHóa Shop', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary))
                    .animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 6),
                const Text('Đăng nhập để mua sắm', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'Số điện thoại',
                  hint: 'Nhập số điện thoại',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập SĐT' : null,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Đăng nhập',
                  onPressed: _handleLogin,
                  isLoading: authProvider.isLoading,
                  icon: Icons.login_rounded,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Đăng ký ngay', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 24),
                // Demo accounts
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStart.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryStart.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔑 Tài khoản demo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _buildDemoAccount('Khách hàng', '0987654321', '123456'),
                      const SizedBox(height: 4),
                      _buildDemoAccount('Admin', '0901234567', '123456'),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccount(String role, String phone, String pass) {
    return GestureDetector(
      onTap: () {
        _phoneController.text = phone;
        _passwordController.text = pass;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '$role: $phone / $pass',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
