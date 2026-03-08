import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiService();
  int _step = 0; // 0: phone, 1: OTP, 2: new password
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _resetToken;
  String? _otpDisplay;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  Future<void> _requestOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return _showError('Vui lòng nhập số điện thoại');

    setState(() => _isLoading = true);
    final res = await _api.post('/auth/forgot-password', body: {'phone': phone});
    setState(() => _isLoading = false);

    if (res.success) {
      // In dev mode, OTP is returned in response for testing
      _otpDisplay = res.data?['otp']?.toString();
      setState(() => _step = 1);
      _showSuccess('Mã OTP đã được gửi');
    } else {
      _showError(res.message ?? 'Không thể gửi OTP');
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return _showError('OTP phải gồm 6 chữ số');

    setState(() => _isLoading = true);
    final res = await _api.post('/auth/verify-otp', body: {
      'phone': _phoneController.text.trim(),
      'otp': otp,
    });
    setState(() => _isLoading = false);

    if (res.success) {
      _resetToken = res.data?['resetToken'];
      setState(() => _step = 2);
    } else {
      _showError(res.message ?? 'OTP không đúng');
    }
  }

  Future<void> _resetPassword() async {
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (pass.length < 6) return _showError('Mật khẩu tối thiểu 6 ký tự');
    if (pass != confirm) return _showError('Mật khẩu không khớp');

    setState(() => _isLoading = true);
    final res = await _api.post('/auth/reset-password', body: {
      'reset_token': _resetToken,
      'new_password': pass,
    });
    setState(() => _isLoading = false);

    if (res.success) {
      _showSuccess('Đặt lại mật khẩu thành công!');
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pop(context);
      }
    } else {
      _showError(res.message ?? 'Không thể đặt lại mật khẩu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 32),
              // Step content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0
                    ? _buildPhoneStep()
                    : _step == 1
                        ? _buildOTPStep()
                        : _buildPasswordStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'SĐT'),
        _buildStepLine(0),
        _buildStepDot(1, 'OTP'),
        _buildStepLine(1),
        _buildStepDot(2, 'Mật khẩu'),
      ],
    ).animate().fadeIn();
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _step >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : AppColors.surfaceLight,
              boxShadow: isActive ? AppColors.buttonShadow : null,
            ),
            child: Center(
              child: isActive && _step > step
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : Text('${step + 1}', style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.primaryStart : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _step > afterStep;
    return Container(
      height: 3, width: 30,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.surfaceLight,
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone'),
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.phone_android_rounded, size: 32, color: AppColors.primaryStart),
        ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
        const SizedBox(height: 16),
        const Text('Nhập số điện thoại', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Chúng tôi sẽ gửi mã OTP đến SĐT của bạn', style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 28),
        CustomTextField(
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại đã đăng ký',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Gửi mã OTP',
          onPressed: _requestOTP,
          isLoading: _isLoading,
          icon: Icons.send_rounded,
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      key: const ValueKey('otp'),
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.pin_rounded, size: 32, color: AppColors.warning),
        ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
        const SizedBox(height: 16),
        const Text('Nhập mã OTP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Mã đã được gửi đến ${_phoneController.text}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        if (_otpDisplay != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Text('🔑 Mã OTP (dev): $_otpDisplay', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success, fontFamily: 'monospace')),
          ),
        ],
        const SizedBox(height: 28),
        CustomTextField(
          label: 'Mã OTP',
          hint: 'Nhập 6 chữ số',
          controller: _otpController,
          prefixIcon: Icons.dialpad_rounded,
          keyboardType: TextInputType.number,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Xác nhận OTP',
          onPressed: _verifyOTP,
          isLoading: _isLoading,
          icon: Icons.verified_rounded,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _requestOTP,
          child: const Text('Gửi lại OTP', style: TextStyle(color: AppColors.primaryStart)),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      key: const ValueKey('password'),
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.lock_reset_rounded, size: 32, color: AppColors.success),
        ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
        const SizedBox(height: 16),
        const Text('Đặt mật khẩu mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Nhập mật khẩu mới cho tài khoản', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        CustomTextField(
          label: 'Mật khẩu mới',
          hint: 'Tối thiểu 6 ký tự',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Xác nhận mật khẩu',
          hint: 'Nhập lại mật khẩu mới',
          controller: _confirmController,
          prefixIcon: Icons.lock_rounded,
          isPassword: true,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Đặt lại mật khẩu',
          onPressed: _resetPassword,
          isLoading: _isLoading,
          icon: Icons.check_circle_rounded,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}
