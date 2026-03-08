import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../models/product.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _productsRaw = [];
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  String? _selectedCategoryId;
  String _statusFilter = 'all'; // all, active, inactive, out_of_stock

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final response = await _api.get(ApiConstants.categories);
    if (response.success && response.data != null) {
      _categories = List<Map<String, dynamic>>.from(response.data);
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final params = <String, String>{};
    if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text;
    if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId!;

    switch (_statusFilter) {
      case 'active':
        params['is_active'] = 'true';
        break;
      case 'inactive':
        params['is_active'] = 'false';
        break;
      case 'out_of_stock':
        params['stock_status'] = 'out';
        break;
    }

    final response = await _api.get(ApiConstants.adminProducts, queryParams: params);
    if (response.success && response.data != null) {
      _productsRaw = (response.data as List).cast<Map<String, dynamic>>();
      _products = _productsRaw.map((e) => Product.fromJson(e)).toList();
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sản phẩm (${_products.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
          );
          if (result == true) _loadProducts();
        },
        backgroundColor: AppColors.primaryStart,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _searchCtrl.clear(); _loadProducts(); })
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Filter row: Category dropdown + Status chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Category dropdown
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _selectedCategoryId != null ? AppColors.primaryStart : AppColors.textLight.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCategoryId,
                        hint: const Text('Danh mục', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả danh mục')),
                          ..._categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'] ?? ''))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                          _loadProducts();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _statusChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _statusChip('Đang bán', 'active'),
                const SizedBox(width: 8),
                _statusChip('Đã ẩn', 'inactive'),
                const SizedBox(width: 8),
                _statusChip('Hết hàng', 'out_of_stock'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
                : _products.isEmpty
                    ? const Center(child: Text('Không tìm thấy sản phẩm', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final rawData = _productsRaw[index];

                            return Dismissible(
                              key: Key(product.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(product),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AdminProductFormScreen(productData: rawData)),
                                  );
                                  if (result == true) _loadProducts();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppColors.cardShadow,
                                    border: !product.isActive ? Border.all(color: AppColors.error.withValues(alpha: 0.2)) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 56, height: 56,
                                          color: AppColors.surfaceLight,
                                          child: product.imageUrl != null
                                              ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.textLight))
                                              : const Icon(Icons.inventory_2_outlined, color: AppColors.textLight),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                if (!product.isActive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                    child: const Text('Ẩn', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text('${currencyFormat.format(product.price)}₫', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryStart)),
                                                const SizedBox(width: 8),
                                                Text('Kho: ${product.stockQuantity}', style: TextStyle(fontSize: 12, color: product.stockQuantity > 0 ? AppColors.textSecondary : AppColors.error)),
                                                if (product.categoryName != null) ...[
                                                  const SizedBox(width: 8),
                                                  Text('• ${product.categoryName}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 22),
                                      if (!product.isActive)
                                        IconButton(
                                          icon: const Icon(Icons.visibility_rounded, color: Color(0xFF059669), size: 22),
                                          tooltip: 'Kích hoạt lại',
                                          onPressed: () => _toggleActive(product),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 250.ms);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadProducts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryStart.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primaryStart : AppColors.textLight.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryStart : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleActive(Product product) async {
    final response = await _api.patch('${ApiConstants.adminProducts}/${product.id}/toggle-active');
    if (response.success) {
      _loadProducts();
      if (mounted) {
        final newStatus = !(product.isActive);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Đã kích hoạt sản phẩm' : 'Đã ẩn sản phẩm'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    }
  }

  Future<bool> _confirmDelete(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ẩn sản phẩm?'),
        content: Text('Bạn có chắc muốn ẩn "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ẩn', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == true) {
      final response = await _api.delete('${ApiConstants.adminProducts}/${product.id}');
      if (response.success) {
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã ẩn sản phẩm'), backgroundColor: Color(0xFF059669)),
          );
        }
      }
    }
    return false;
  }
}
