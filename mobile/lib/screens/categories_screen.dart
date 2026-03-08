import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _api = ApiService();
  int? _selectedCategoryId;
  List<Product> _categoryProducts = [];
  bool _isLoadingProducts = false;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.categories.isEmpty) {
        provider.loadProducts().then((_) {
          _selectFirstCategory();
        });
      } else {
        _selectFirstCategory();
      }
    });
  }

  void _selectFirstCategory() {
    final categories = context.read<ProductProvider>().categories;
    if (categories.isNotEmpty && _selectedCategoryId == null) {
      _selectCategory(categories.first.id);
    }
  }

  Future<void> _selectCategory(int categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoadingProducts = true;
      _isExpanded = true;
    });

    final response = await _api.get(ApiConstants.products, queryParams: {
      'category_id': categoryId.toString(),
    });

    if (response.success && response.data != null && mounted) {
      setState(() {
        _categoryProducts = (response.data as List)
            .map((e) => Product.fromJson(e))
            .toList();
        _isLoadingProducts = false;
      });
    } else if (mounted) {
      setState(() {
        _categoryProducts = [];
        _isLoadingProducts = false;
      });
    }
  }

  String _getCategoryName() {
    final categories = context.read<ProductProvider>().categories;
    final cat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    return cat?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Search bar ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.primaryStart,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                    child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_rounded, size: 20, color: AppColors.textLight),
                            SizedBox(width: 8),
                            Text('Tìm sản phẩm...', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/cart'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                        Consumer<CartProvider>(
                          builder: (_, cart, __) {
                            if (cart.totalItemsCount == 0) return const SizedBox();
                            return Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${cart.totalItemsCount}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Split view ─────────────────────────────────
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
                  : categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, size: 64, color: AppColors.textLight.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('Chưa có danh mục nào', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Left sidebar ──────────────
                            _buildSidebar(categories),

                            // ─── Right content ─────────────
                            Expanded(child: _buildContent()),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SIDEBAR
  // ═══════════════════════════════════════════════════════════
  Widget _buildSidebar(List<Category> categories) {
    return Container(
      width: 90,
      color: const Color(0xFFF3F4F6),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == _selectedCategoryId;

          return GestureDetector(
            onTap: () => _selectCategory(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? AppColors.primaryStart : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category icon/image
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryStart.withValues(alpha: 0.08)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: cat.imageUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Icon(
                                Icons.category_rounded,
                                size: 22,
                                color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.category_rounded,
                                size: 22,
                                color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.category_rounded,
                            size: 22,
                            color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                          ),
                  ),
                  const SizedBox(height: 6),
                  // Category name
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryStart : AppColors.textSecondary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENT (right side)
  // ═══════════════════════════════════════════════════════════
  Widget _buildContent() {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');
    final categoryName = _getCategoryName();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
            ),
            child: Text(
              categoryName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Products grid
          Expanded(
            child: _isLoadingProducts
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primaryStart, strokeWidth: 2.5),
                    ),
                  )
                : _categoryProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textLight.withValues(alpha: 0.4)),
                              const SizedBox(height: 10),
                              const Text('Chưa có sản phẩm', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Products grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.6,
                              ),
                              itemCount: _isExpanded
                                  ? _categoryProducts.length
                                  : (_categoryProducts.length > 9 ? 9 : _categoryProducts.length),
                              itemBuilder: (context, index) {
                                final product = _categoryProducts[index];
                                return _buildProductItem(product, currencyFormat);
                              },
                            ),

                            // Expand/Collapse button
                            if (_categoryProducts.length > 9) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => setState(() => _isExpanded = !_isExpanded),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isExpanded ? 'Thu gọn' : 'Xem thêm (${_categoryProducts.length - 9})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PRODUCT ITEM
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductItem(Product product, NumberFormat fmt) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image — fixed size
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.textLight, size: 28),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.textLight, size: 28),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined, color: AppColors.textLight, size: 28),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Name — fixed 2 lines height
          SizedBox(
            height: 32,
            child: Text(
              product.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Price
          Text(
            '${fmt.format(product.price)}₫',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryStart,
            ),
          ),
        ],
      ),
    );
  }
}
