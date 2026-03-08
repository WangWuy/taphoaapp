import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final response = await _api.get('${ApiConstants.adminOrders}/${widget.orderId}');
    if (response.success && response.data != null) {
      _order = response.data as Map<String, dynamic>;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _navigateToProduct(String productId) async {
    final response = await _api.get('${ApiConstants.products}/$productId');
    if (response.success && response.data != null && mounted) {
      final product = Product.fromJson(response.data);
      Navigator.pushNamed(context, '/product-detail', arguments: product);
    }
  }

  num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  final _statusFlow = {
    'pending': {'next': 'confirmed', 'label': 'Xác nhận', 'icon': Icons.check_circle_rounded, 'color': Color(0xFF3B82F6)},
    'confirmed': {'next': 'shipping', 'label': 'Giao hàng', 'icon': Icons.local_shipping_rounded, 'color': Color(0xFFF59E0B)},
    'preparing': {'next': 'shipping', 'label': 'Giao hàng', 'icon': Icons.local_shipping_rounded, 'color': Color(0xFFF59E0B)}, // backward compat
    'shipping': {'next': 'delivered', 'label': 'Đã giao', 'icon': Icons.check_circle_rounded, 'color': Color(0xFF10B981)},
  };

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final response = await _api.patch(
      '${ApiConstants.adminOrders}/${widget.orderId}/status',
      body: {'status': newStatus},
    );
    setState(() => _isUpdating = false);

    if (response.success) {
      _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái'), backgroundColor: Color(0xFF059669)),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Lỗi cập nhật'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này? Số lượng tồn kho sẽ được hoàn lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy đơn', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus('cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context, true)),
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : _order == null
              ? const Center(child: Text('Không tìm thấy đơn hàng'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadOrder,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOrderHeader(currencyFormat),
                              const SizedBox(height: 16),
                              _buildCustomerSection(),
                              const SizedBox(height: 16),
                              _buildItemsSection(currencyFormat),
                              const SizedBox(height: 16),
                              _buildAddressSection(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Fixed bottom action buttons
                    _buildBottomActions(),
                  ],
                ),
    );
  }

  Widget _buildOrderHeader(NumberFormat fmt) {
    final status = _order!['status'] ?? 'pending';
    final orderNumber = _order!['order_number'] ?? '';
    final total = _parseNum(_order!['total']);
    final createdAt = (_order!['created_at'] ?? _order!['createdAt']) != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse((_order!['created_at'] ?? _order!['createdAt'])))
        : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ngày đặt: $createdAt', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              Text('${fmt.format(total)}₫', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryStart)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCustomerSection() {
    final customer = _order!['customer'] as Map<String, dynamic>?;
    if (customer == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Khách hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.person_outline_rounded, customer['name'] ?? ''),
          _buildInfoRow(Icons.phone_outlined, customer['phone'] ?? ''),
          if (customer['email'] != null) _buildInfoRow(Icons.email_outlined, customer['email']),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildItemsSection(NumberFormat fmt) {
    final items = (_order!['items'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sản phẩm (${items.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...items.map((item) {
            final product = item['product'] as Map<String, dynamic>?;
            final productId = item['product_id'] ?? product?['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap: productId != null ? () => _navigateToProduct(productId) : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44, height: 44,
                        color: AppColors.surfaceLight,
                        child: ApiConstants.getFullImageUrl(product?['image_url']) != null
                            ? Image.network(ApiConstants.getFullImageUrl(product!['image_url'])!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 20, color: AppColors.textLight))
                            : const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['product_name'] ?? product?['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('x${item['quantity']} • ${fmt.format(_parseNum(item['product_price']))}₫', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text('${fmt.format(_parseNum(item['subtotal']))}₫', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildAddressSection() {
    final address = _order!['shippingAddress'] as Map<String, dynamic>?;
    if (address == null) return const SizedBox();

    final fullAddress = [
      address['address_line'] ?? address['addressLine'],
      address['ward'],
      address['district'],
      address['city'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Địa chỉ giao hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.person_outline_rounded, address['recipient_name'] ?? address['recipientName'] ?? ''),
          _buildInfoRow(Icons.phone_outlined, address['phone'] ?? ''),
          _buildInfoRow(Icons.location_on_outlined, fullAddress),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildBottomActions() {
    final status = _order!['status'] ?? 'pending';
    final flow = _statusFlow[status];

    if (status == 'delivered' || status == 'cancelled') {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flow != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _updateStatus(flow['next'] as String),
                  icon: _isUpdating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(flow['icon'] as IconData, size: 20),
                  label: Text(flow['label'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: flow['color'] as Color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (status != 'cancelled')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _cancelOrder,
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text('Hủy đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    late Color bgColor, textColor;
    late String text;
    switch (status) {
      case 'pending': bgColor = const Color(0xFFFEF3C7); textColor = const Color(0xFF92400E); text = 'Chờ xác nhận'; break;
      case 'confirmed': bgColor = const Color(0xFFDBEAFE); textColor = const Color(0xFF1E40AF); text = 'Đã xác nhận'; break;
      case 'preparing': bgColor = const Color(0xFFE0E7FF); textColor = const Color(0xFF3730A3); text = 'Đang chuẩn bị'; break;
      case 'shipping': bgColor = const Color(0xFFFED7AA); textColor = const Color(0xFF9A3412); text = 'Đang giao'; break;
      case 'delivered': bgColor = const Color(0xFFD1FAE5); textColor = const Color(0xFF065F46); text = 'Đã giao'; break;
      case 'cancelled': bgColor = const Color(0xFFFEE2E2); textColor = const Color(0xFF991B1B); text = 'Đã hủy'; break;
      default: bgColor = AppColors.surfaceLight; textColor = AppColors.textSecondary; text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
