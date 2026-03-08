import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../models/category.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? productData;

  const AdminProductFormScreen({super.key, this.productData});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();

  int? _selectedCategoryId;
  int? _pendingCategoryId; // Store category ID until categories are loaded
  bool _isActive = true;
  bool _isSaving = false;
  List<Category> _categories = [];
  bool _categoriesLoaded = false;

  // Image
  String? _imageUrl;
  File? _pickedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.productData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.productData!;
      _nameController.text = p['name'] ?? '';
      _descriptionController.text = p['description'] ?? '';
      _priceController.text = (p['price'] ?? 0).toString();
      _comparePriceController.text = p['compare_at_price']?.toString() ?? '';
      _unitController.text = p['unit'] ?? 'cái';
      _stockController.text = (p['stock_quantity'] ?? 0).toString();
      _imageUrl = ApiConstants.getFullImageUrl(p['image_url']);
      _pendingCategoryId = p['category_id'];
      _isActive = p['is_active'] ?? true;
    } else {
      _unitController.text = 'cái';
      _stockController.text = '0';
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final response = await _api.get(ApiConstants.categories);
    if (response.success && response.data != null) {
      setState(() {
        _categories = (response.data as List).map((e) => Category.fromJson(e)).toList();
        // Now that categories are loaded, set the selected category if it exists in the list
        if (_pendingCategoryId != null) {
          final exists = _categories.any((c) => c.id == _pendingCategoryId);
          _selectedCategoryId = exists ? _pendingCategoryId : null;
          _pendingCategoryId = null;
        }
        _categoriesLoaded = true;
      });
    } else {
      setState(() => _categoriesLoaded = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
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
    return _imageUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Upload image first if picked
    final uploadedUrl = await _uploadPickedImage();

    final body = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'compare_at_price': _comparePriceController.text.trim().isEmpty ? null : double.tryParse(_comparePriceController.text),
      'unit': _unitController.text.trim().isEmpty ? 'cái' : _unitController.text.trim(),
      'stock_quantity': int.tryParse(_stockController.text) ?? 0,
      'category_id': _selectedCategoryId,
      'image_url': uploadedUrl,
      'is_active': _isActive,
    };

    final response = _isEditing
        ? await _api.put('${ApiConstants.adminProducts}/${widget.productData!['id']}', body: body)
        : await _api.post(ApiConstants.adminProducts, body: body);

    setState(() => _isSaving = false);

    if (response.success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Đã cập nhật sản phẩm' : 'Đã tạo sản phẩm mới'),
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
        title: Text(_isEditing ? 'Sửa sản phẩm' : 'Tạo sản phẩm', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
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
              _buildLabel('Hình ảnh sản phẩm'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 180,
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
              const SizedBox(height: 18),

              // Name
              _buildLabel('Tên sản phẩm *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Nhập tên sản phẩm'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 18),

              // Description
              _buildLabel('Mô tả'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Mô tả sản phẩm'),
                maxLines: 3,
              ),
              const SizedBox(height: 18),

              // Price row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Giá bán (₫) *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nhập giá';
                            if (double.tryParse(v) == null) return 'Số không hợp lệ';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Giá gốc (₫)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _comparePriceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Tùy chọn'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Unit & Stock row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Đơn vị'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _unitController,
                          decoration: _inputDecoration('cái, kg, hộp...'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tồn kho'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Category
              _buildLabel('Danh mục'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: _inputDecoration('Chọn danh mục').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Không có')),
                    ..._categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
              const SizedBox(height: 18),

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
                  subtitle: Text(_isActive ? 'Sản phẩm đang hiển thị' : 'Sản phẩm đang ẩn',
                      style: TextStyle(fontSize: 13, color: _isActive ? AppColors.success : AppColors.error)),
                  value: _isActive,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
              const SizedBox(height: 40),
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
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.primaryStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.add_photo_alternate_rounded, size: 28, color: AppColors.primaryStart),
        ),
        const SizedBox(height: 10),
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
