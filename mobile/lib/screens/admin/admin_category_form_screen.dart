import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? categoryData;

  const AdminCategoryFormScreen({super.key, this.categoryData});

  @override
  State<AdminCategoryFormScreen> createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sortOrderController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  // Image
  String? _imageUrl;
  File? _pickedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.categoryData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.categoryData!['name'] ?? '';
      _imageUrl = ApiConstants.getFullImageUrl(widget.categoryData!['image_url']);
      _sortOrderController.text = (widget.categoryData!['sort_order'] ?? 0).toString();
      _isActive = widget.categoryData!['is_active'] ?? true;
    } else {
      _loadNextSortOrder();
    }
  }

  Future<void> _loadNextSortOrder() async {
    final response = await _api.get(ApiConstants.adminCategories);
    if (response.success && response.data != null) {
      final categories = response.data as List;
      int maxOrder = 0;
      for (final cat in categories) {
        final order = cat['sort_order'] ?? 0;
        if (order > maxOrder) maxOrder = order;
      }
      if (mounted) {
        setState(() => _sortOrderController.text = (maxOrder + 1).toString());
      }
    } else {
      _sortOrderController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Chọn ảnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chụp ảnh từ camera', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF8B5CF6)),
                ),
                title: const Text('Thư viện ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              if (_imageUrl != null || _pickedImage != null) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text('Xóa ảnh', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () { Navigator.pop(ctx); setState(() { _pickedImage = null; _imageUrl = null; }); },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadPickedImage() async {
    if (_pickedImage == null) return _imageUrl;
    setState(() => _isUploading = true);
    final response = await _api.uploadImage(_pickedImage!);
    setState(() => _isUploading = false);
    if (response.success && response.data != null) {
      return response.data['url'] as String;
    }
    // Upload failed — notify caller
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Upload ảnh thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return null; // Return null to signal failure
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? uploadedUrl = _imageUrl;
    if (_pickedImage != null) {
      uploadedUrl = await _uploadPickedImage();
      if (uploadedUrl == null && _pickedImage != null) {
        // Upload failed, abort save
        setState(() => _isSaving = false);
        return;
      }
    }

    final body = {
      'name': _nameController.text.trim(),
      'image_url': uploadedUrl,
      'is_active': _isActive,
      'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
    };

    final response = _isEditing
        ? await _api.put('${ApiConstants.adminCategories}/${widget.categoryData!['id']}', body: body)
        : await _api.post(ApiConstants.adminCategories, body: body);

    setState(() => _isSaving = false);

    if (response.success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Đã cập nhật danh mục' : 'Đã tạo danh mục mới'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Có lỗi xảy ra'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_isEditing ? 'Sửa danh mục' : 'Tạo danh mục', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_isSaving || _isUploading) ? null : _save,
              child: (_isSaving || _isUploading)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryStart))
                  : const Text('Lưu', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Image Picker ──────────────────────────────
              _buildLabel('Hình ảnh danh mục'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : _imageUrl != null && _imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                              ),
                            )
                          : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _buildLabel('Tên danh mục *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nhập tên danh mục'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 20),

              // Sort order
              _buildLabel('Thứ tự hiển thị'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('0'),
              ),
              const SizedBox(height: 20),

              // Active toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hiển thị', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(_isActive ? 'Danh mục đang hiển thị' : 'Danh mục đang ẩn',
                      style: TextStyle(fontSize: 13, color: _isActive ? AppColors.success : AppColors.error)),
                  value: _isActive,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primaryStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.add_photo_alternate_rounded, size: 24, color: AppColors.primaryStart),
        ),
        const SizedBox(height: 8),
        const Text('Chụp ảnh hoặc chọn từ thư viện', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryStart, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
    );
  }
}
