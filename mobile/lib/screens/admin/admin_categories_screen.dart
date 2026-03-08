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
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final response = await _api.get(ApiConstants.adminCategories);
    if (response.success && response.data != null) {
      _categories = (response.data as List).cast<Map<String, dynamic>>();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Danh mục (${_categories.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = cat['is_active'] ?? true;
                  final productCount = cat['productCount'] ?? 0;

                  return Dismissible(
                    key: Key(cat['id'].toString()),
                    direction: DismissDirection.endToStart,
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
                            // Category image/icon
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
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 250.ms);
                },
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
    return false; // Don't auto-dismiss, we reload manually
  }
}
