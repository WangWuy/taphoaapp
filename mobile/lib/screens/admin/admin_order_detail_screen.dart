import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return null;
    }
  }

  final _statusFlow = {
    'pending': {'next': 'confirmed', 'label': 'Xác nhận', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF3B82F6)},
    'confirmed': {'next': 'shipping', 'label': 'Giao hàng', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFFF59E0B)},
    'preparing': {'next': 'shipping', 'label': 'Giao hàng', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFFF59E0B)},
    'shipping': {'next': 'delivered', 'label': 'Đã giao', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
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
    final fmt = NumberFormat('#,##0', 'vi_VN');

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
                              _buildOrderHeader(fmt),
                              const SizedBox(height: 16),
                              _buildCustomerSection(),
                              const SizedBox(height: 16),
                              _buildItemsSection(fmt),
                              const SizedBox(height: 16),
                              _buildAddressSection(),
                              const SizedBox(height: 16),
                              _buildPaymentSection(),
                              const SizedBox(height: 16),
                              _buildSummarySection(fmt),
                              const SizedBox(height: 16),
                              _buildTimelineSection(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ORDER HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildOrderHeader(NumberFormat fmt) {
    final status = _order!['status'] ?? 'pending';
    final orderNumber = _order!['order_number'] ?? '';
    final createdAt = _parseDate(_order!['created_at'] ?? _order!['createdAt']) ?? '';

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
              Expanded(
                child: Row(
                  children: [
                    Text(orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: orderNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã copy mã đơn'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryStart),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ngày đặt: $createdAt', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOMER
  // ═══════════════════════════════════════════════════════════
  Widget _buildCustomerSection() {
    final customer = _order!['customer'] as Map<String, dynamic>?;
    if (customer == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primaryStart),
              SizedBox(width: 8),
              Text('Khách hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.person_outline_rounded, customer['name'] ?? ''),
          _buildInfoRow(Icons.phone_outlined, customer['phone'] ?? ''),
          if (customer['email'] != null && customer['email'].toString().isNotEmpty)
            _buildInfoRow(Icons.email_outlined, customer['email']),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════
  // ITEMS
  // ═══════════════════════════════════════════════════════════
  Widget _buildItemsSection(NumberFormat fmt) {
    final items = (_order!['items'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.primaryStart),
              const SizedBox(width: 8),
              Text('Sản phẩm (${items.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final product = item['product'] as Map<String, dynamic>?;
            final productId = item['product_id'] ?? product?['id'];
            return Column(
              children: [
                if (index > 0) const Divider(height: 16),
                GestureDetector(
                  onTap: productId != null ? () => _navigateToProduct(productId) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 52, height: 52,
                          color: AppColors.surfaceLight,
                          child: ApiConstants.getFullImageUrl(product?['image_url']) != null
                              ? Image.network(ApiConstants.getFullImageUrl(product!['image_url'])!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 22, color: AppColors.textLight))
                              : const Icon(Icons.inventory_2_outlined, size: 22, color: AppColors.textLight),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? product?['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text('${fmt.format(_parseNum(item['product_price']))}₫ × ${item['quantity']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${fmt.format(_parseNum(item['subtotal']))}₫', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryStart)),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════
  // ADDRESS
  // ═══════════════════════════════════════════════════════════
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
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Địa chỉ giao hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(address['recipient_name'] ?? address['recipientName'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Text(address['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(fullAddress, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════
  // PAYMENT & NOTE
  // ═══════════════════════════════════════════════════════════
  Widget _buildPaymentSection() {
    final paymentMethod = _order!['payment_method'] ?? _order!['paymentMethod'] ?? 'cod';
    final paymentStatus = _order!['payment_status'] ?? _order!['paymentStatus'] ?? 'pending';
    final note = _order!['note'];

    String paymentText;
    IconData paymentIcon;
    switch (paymentMethod) {
      case 'bank_transfer':
        paymentText = 'Chuyển khoản ngân hàng';
        paymentIcon = Icons.account_balance_rounded;
        break;
      default:
        paymentText = 'Thanh toán khi nhận hàng (COD)';
        paymentIcon = Icons.payments_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(paymentIcon, size: 20, color: const Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              const Text('Thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paymentText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                _buildPaymentStatusBadge(paymentStatus, paymentMethod),
              ],
            ),
          ),
          if (note != null && note.toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.note_alt_outlined, size: 20, color: Color(0xFF8B5CF6)),
                SizedBox(width: 8),
                Text('Ghi chú', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(note.toString(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  Widget _buildPaymentStatusBadge(String status, String paymentMethod) {
    Color bgColor;
    Color textColor;
    String text;

    if (paymentMethod == 'cod' && status == 'pending') {
      bgColor = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF1E40AF);
      text = 'Thanh toán khi nhận hàng';
    } else {
      switch (status) {
        case 'paid':
          bgColor = const Color(0xFFD1FAE5);
          textColor = const Color(0xFF065F46);
          text = 'Đã thanh toán';
          break;
        case 'pending':
          bgColor = const Color(0xFFFEF3C7);
          textColor = const Color(0xFF92400E);
          text = 'Chờ thanh toán';
          break;
        case 'refunded':
          bgColor = const Color(0xFFE0E7FF);
          textColor = const Color(0xFF3730A3);
          text = 'Đã hoàn tiền';
          break;
        default:
          bgColor = AppColors.surfaceLight;
          textColor = AppColors.textSecondary;
          text = status;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SUMMARY (Price breakdown)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSummarySection(NumberFormat fmt) {
    final subtotal = _parseNum(_order!['subtotal']);
    final shippingFee = _parseNum(_order!['shipping_fee'] ?? _order!['shippingFee']);
    final total = _parseNum(_order!['total']);
    final items = (_order!['items'] as List?) ?? [];
    final isFreeShip = shippingFee == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.primaryStart),
              SizedBox(width: 8),
              Text('Tổng kết', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Tiền hàng (${items.length} SP)', '${fmt.format(subtotal)}₫'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Phí giao hàng',
            isFreeShip ? 'Miễn phí' : '${fmt.format(shippingFee)}₫',
            valueColor: isFreeShip ? const Color(0xFF059669) : null,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${fmt.format(total)}₫', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryStart)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 14, color: valueColor ?? AppColors.textPrimary, fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TIMELINE
  // ═══════════════════════════════════════════════════════════
  Widget _buildTimelineSection() {
    final orderedAt = _parseDate(_order!['ordered_at'] ?? _order!['orderedAt'] ?? _order!['created_at'] ?? _order!['createdAt']);
    final shippedAt = _parseDate(_order!['shipped_at'] ?? _order!['shippedAt']);
    final deliveredAt = _parseDate(_order!['delivered_at'] ?? _order!['deliveredAt']);
    final cancelledAt = _parseDate(_order!['cancelled_at'] ?? _order!['cancelledAt']);

    final events = <_TimelineEvent>[];
    if (orderedAt != null) events.add(_TimelineEvent('Đặt hàng', orderedAt, Icons.shopping_cart_outlined, const Color(0xFF3B82F6)));
    if (shippedAt != null) events.add(_TimelineEvent('Bắt đầu giao', shippedAt, Icons.local_shipping_outlined, const Color(0xFFF59E0B)));
    if (deliveredAt != null) events.add(_TimelineEvent('Đã giao', deliveredAt, Icons.check_circle_rounded, const Color(0xFF059669)));
    if (cancelledAt != null) events.add(_TimelineEvent('Đã hủy', cancelledAt, Icons.cancel_rounded, AppColors.error));

    if (events.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 20, color: AppColors.primaryStart),
              SizedBox(width: 8),
              Text('Lịch sử đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ...events.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isLast = i == events.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: e.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(e.icon, size: 16, color: e.color),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(width: 2, color: AppColors.divider),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(e.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms, duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM ACTIONS
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
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

class _TimelineEvent {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimelineEvent(this.label, this.time, this.icon, this.color);
}
