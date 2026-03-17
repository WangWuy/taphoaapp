import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../models/category.dart';
import 'admin_category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _allCategories = [];
  bool _isLoading = true;
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    switch (_statusFilter) {
      case 'active':
        return _allCategories.where((c) => c['is_active'] == true).toList();
      case 'inactive':
        return _allCategories.where((c) => c['is_active'] == false).toList();
      default:
        return _allCategories;
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final response = await _api.get(ApiConstants.adminCategories);
    if (response.success && response.data != null) {
      _allCategories = (response.data as List).cast<Map<String, dynamic>>();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleActive(Map<String, dynamic> cat) async {
    final newActive = !(cat['is_active'] ?? true);
    final response = await _api.put(
      '${ApiConstants.adminCategories}/${cat['id']}',
      body: {'is_active': newActive},
    );
    if (response.success) {
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Đã kích hoạt "${cat['name']}"' : 'Đã ẩn "${cat['name']}"'),
            backgroundColor: newActive ? const Color(0xFF059669) : AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Danh mục (${_allCategories.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryFormScreen()),
          );
          if (result == true) _loadCategories();
        },
        backgroundColor: AppColors.primaryStart,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _statusChip('Đang hoạt động', 'active'),
                const SizedBox(width: 8),
                _statusChip('Đã ẩn', 'inactive'),
                const SizedBox(width: 8),
                _statusChip('Tất cả', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Category list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
                : categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _statusFilter == 'inactive' ? Icons.archive_outlined : Icons.category_outlined,
                              size: 56,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _statusFilter == 'inactive' ? 'Không có danh mục đã ẩn' : 'Chưa có danh mục nào',
                              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isActive = cat['is_active'] ?? true;
                            final productCount = cat['productCount'] ?? 0;

                            return Dismissible(
                              key: Key(cat['id'].toString()),
                              direction: isActive ? DismissDirection.endToStart : DismissDirection.none,
                              confirmDismiss: (_) => _confirmDelete(cat),
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
                                    MaterialPageRoute(builder: (_) => AdminCategoryFormScreen(categoryData: cat)),
                                  );
                                  if (result == true) _loadCategories();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppColors.cardShadow,
                                    border: !isActive ? Border.all(color: AppColors.error.withValues(alpha: 0.2)) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 48, height: 48,
                                          color: AppColors.primaryStart.withValues(alpha: 0.1),
                                          child: cat['image_url'] != null && (cat['image_url'] as String).isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: ApiConstants.getFullImageUrl(cat['image_url'])!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => const Icon(Icons.category_rounded, color: AppColors.primaryStart, size: 24),
                                                  errorWidget: (_, __, ___) => const Icon(Icons.category_rounded, color: AppColors.primaryStart, size: 24),
                                                )
                                              : const Icon(Icons.category_rounded, color: AppColors.primaryStart, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: Text(cat['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                                                if (!isActive)
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
                                                Text('$productCount sản phẩm', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                const SizedBox(width: 12),
                                                Text('Thứ tự: ${cat['sort_order'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 22),
                                      if (!isActive)
                                        IconButton(
                                          icon: const Icon(Icons.visibility_rounded, color: Color(0xFF059669), size: 22),
                                          tooltip: 'Kích hoạt lại',
                                          onPressed: () => _toggleActive(cat),
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

  Future<bool> _confirmDelete(Map<String, dynamic> cat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa danh mục?'),
        content: Text('Bạn có chắc muốn xóa "${cat['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == true) {
      final response = await _api.delete('${ApiConstants.adminCategories}/${cat['id']}');
      if (response.success) {
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data?.toString() ?? 'Đã xóa danh mục'), backgroundColor: const Color(0xFF059669)),
          );
        }
      }
    }
    return false;
  }
}
