import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/address_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDefault = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Thêm địa chỉ mới', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(label: 'Người nhận', hint: 'Nhập tên người nhận', controller: _nameController, prefixIcon: Icons.person_outline_rounded, validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null),
              const SizedBox(height: 14),
              CustomTextField(label: 'Số điện thoại', hint: 'Nhập SĐT người nhận', controller: _phoneController, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập SĐT' : null),
              const SizedBox(height: 14),
              CustomTextField(label: 'Địa chỉ chi tiết', hint: 'Số nhà, tên đường...', controller: _addressController, prefixIcon: Icons.home_outlined, validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập địa chỉ' : null),
              const SizedBox(height: 14),
              CustomTextField(label: 'Phường/Xã', hint: 'Nhập phường/xã', controller: _wardController, prefixIcon: Icons.location_city_outlined),
              const SizedBox(height: 14),
              CustomTextField(label: 'Quận/Huyện', hint: 'Nhập quận/huyện', controller: _districtController, prefixIcon: Icons.map_outlined),
              const SizedBox(height: 14),
              CustomTextField(label: 'Tỉnh/Thành phố', hint: 'Nhập tỉnh/thành phố', controller: _cityController, prefixIcon: Icons.location_on_outlined, validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập thành phố' : null),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _isDefault = !_isDefault),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                  child: Row(
                    children: [
                      Icon(_isDefault ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: _isDefault ? AppColors.primaryStart : AppColors.textLight),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontSize: 14, color: AppColors.textPrimary))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Lưu địa chỉ', onPressed: _saveAddress, icon: Icons.save_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final addressProvider = context.read<AddressProvider>();
    final success = await addressProvider.createAddress(
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressController.text.trim(),
      ward: _wardController.text.trim().isEmpty ? null : _wardController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      city: _cityController.text.trim(),
      isDefault: _isDefault,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu địa chỉ'), backgroundColor: Color(0xFF059669)));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(addressProvider.error ?? 'Lỗi'), backgroundColor: AppColors.error));
    }
  }
}
