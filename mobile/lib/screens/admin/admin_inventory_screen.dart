import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _stockFilter = 'all';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      setState(() => _categories = List<Map<String, dynamic>>.from(response.data));
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final params = <String, String>{};
    if (_stockFilter != 'all') params['stock_status'] = _stockFilter;
    if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text;
    if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId!;

    final response = await _api.get('${ApiConstants.adminProducts}/inventory', queryParams: params);
    if (response.success && response.data != null) {
      _products = List<Map<String, dynamic>>.from(response.data);
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadData();
    });
  }

  void _setFilter(String filter) {
    setState(() => _stockFilter = filter);
    _loadData();
  }

  Color _stockColor(int qty) {
    if (qty == 0) return AppColors.error;
    if (qty <= 10) return AppColors.warning;
    return AppColors.success;
  }

  String _stockLabel(int qty) {
    if (qty == 0) return 'Hết hàng';
    if (qty <= 10) return 'Sắp hết';
    return 'Còn hàng';
  }

  void _showStockEditSheet(Map<String, dynamic> product) {
    final qtyCtrl = TextEditingController(text: '${product['stock_quantity']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(product['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Tồn kho hiện tại: ${product['stock_quantity']} ${product['unit'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            Row(
              children: [
                _quickAdjustButton(-50, product),
                const SizedBox(width: 8),
                _quickAdjustButton(-10, product),
                const SizedBox(width: 8),
                _quickAdjustButton(-1, product),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryStart, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _quickAdjustButton(1, product),
                const SizedBox(width: 8),
                _quickAdjustButton(10, product),
                const SizedBox(width: 8),
                _quickAdjustButton(50, product),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text);
                  if (qty == null || qty < 0) return;
                  final resp = await _api.patch(
                    '${ApiConstants.adminProducts}/${product['id']}/stock',
                    body: {'quantity': qty},
                  );
                  if (resp.success && mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật tồn kho'), backgroundColor: Color(0xFF059669)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Cập nhật', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAdjustButton(int delta, Map<String, dynamic> product) {
    final isPositive = delta > 0;
    return GestureDetector(
      onTap: () async {
        final resp = await _api.patch(
          '${ApiConstants.adminProducts}/${product['id']}/stock',
          body: {'adjustment': delta},
        );
        if (resp.success) {
          Navigator.pop(context);
          _loadData();
        }
      },
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isPositive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '${isPositive ? '+' : ''}$delta',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isPositive ? AppColors.success : AppColors.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tồn kho (${_products.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _searchCtrl.clear(); _loadData(); })
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Category dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _selectedCategoryId != null ? AppColors.primaryStart : AppColors.textLight.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedCategoryId,
                  hint: const Text('Tất cả danh mục', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả danh mục')),
                    ..._categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'] ?? ''))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                    _loadData();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('Tất cả', 'all', null),
                const SizedBox(width: 8),
                _filterChip('Hết hàng', 'out_of_stock', AppColors.error),
                const SizedBox(width: 8),
                _filterChip('Sắp hết', 'low_stock', AppColors.warning),
                const SizedBox(width: 8),
                _filterChip('Còn hàng', 'in_stock', AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
                : _products.isEmpty
                    ? const Center(child: Text('Không tìm thấy sản phẩm', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final qty = product['stock_quantity'] ?? 0;
                            final color = _stockColor(qty);
                            final category = product['category'] as Map<String, dynamic>?;

                            return GestureDetector(
                              onTap: () => _showStockEditSheet(product),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 50, height: 50,
                                        color: AppColors.surfaceLight,
                                        child: ApiConstants.getFullImageUrl(product['image_url']) != null
                                            ? Image.network(ApiConstants.getFullImageUrl(product['image_url'])!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: AppColors.textLight))
                                            : const Icon(Icons.inventory_2_outlined, color: AppColors.textLight),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text('${currencyFormat.format(double.tryParse(product['price']?.toString() ?? '0') ?? 0)}₫', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                              if (category != null) ...[
                                                const SizedBox(width: 6),
                                                Text('• ${category['name']}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Text('$qty ${product['unit'] ?? ''}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(_stockLabel(qty), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_outlined, size: 18, color: AppColors.textLight),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: 40 * index), duration: 250.ms);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, Color? color) {
    final isSelected = _stockFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.primaryStart).withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? (color ?? AppColors.primaryStart) : AppColors.textLight.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? (color ?? AppColors.primaryStart) : AppColors.textSecondary)),
      ),
    );
  }
}
