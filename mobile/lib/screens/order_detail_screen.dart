import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/order_provider.dart';
import '../providers/config_provider.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _api = ApiService();
  Order? _order;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_order == null) {
      final orderId = ModalRoute.of(context)?.settings.arguments as String?;
      if (orderId != null) _loadOrder(orderId);
    }
  }

  Future<void> _loadOrder(String orderId) async {
    setState(() => _isLoading = true);
    final response = await _api.get('${ApiConstants.orders}/$orderId');
    if (response.success && response.data != null && mounted) {
      setState(() {
        _order = Order.fromJson(response.data);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToProduct(String productId) async {
    final response = await _api.get('${ApiConstants.products}/$productId');
    if (response.success && response.data != null && mounted) {
      final product = Product.fromJson(response.data);
      Navigator.pushNamed(context, '/product-detail', arguments: product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : _order == null
              ? const Center(child: Text('Không tìm thấy đơn hàng', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: () => _loadOrder(_order!.id),
                  color: AppColors.primaryStart,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ─── Order status header ─────────────────
                        _buildStatusHeader(dateFormat).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 14),

                        // ─── Items ───────────────────────────────
                        _buildItemsSection(currencyFormat).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                        const SizedBox(height: 14),

                        // ─── Address ─────────────────────────────
                        if (_order!.shippingAddress != null)
                          _buildAddressSection().animate().fadeIn(delay: 200.ms, duration: 300.ms),
                        if (_order!.shippingAddress != null) const SizedBox(height: 14),

                        // ─── Payment & Note ──────────────────────
                        _buildPaymentSection().animate().fadeIn(delay: 300.ms, duration: 300.ms),
                        const SizedBox(height: 14),

                        // ─── Summary ─────────────────────────────
                        _buildSummarySection(currencyFormat).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                        // ─── Cancel button ───────────────────────
                        if (_order!.canCancel) ...[
                          const SizedBox(height: 20),
                          _buildCancelButton(),
                        ],

                        // ─── Confirm delivery button (customer) ──
                        if (_order!.status == 'shipping') ...[
                          const SizedBox(height: 16),
                          _buildConfirmDeliveryButton(),
                        ],

                        // ─── Confirm bank transfer button ──
                        if (_order!.paymentMethod == 'bank_transfer' &&
                            _order!.paymentStatus == 'pending' &&
                            _order!.status != 'cancelled') ...[
                          const SizedBox(height: 16),
                          _buildConfirmPaymentButton(),
                        ],

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatusHeader(DateFormat dateFormat) {
    final order = _order!;
    DateTime? createdDate;
    if (order.createdAt != null) {
      createdDate = DateTime.tryParse(order.createdAt!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Status icon
          _buildStatusIcon(order.status),
          const SizedBox(height: 12),
          // Status text
          Text(
            order.statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _statusColor(order.status),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Order info rows
          _buildInfoRow('Mã đơn hàng', order.orderNumber, copyable: true),
          const SizedBox(height: 6),
          if (createdDate != null) _buildInfoRow('Ngày đặt', dateFormat.format(createdDate.toLocal())),
          if (order.deliveredAt != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow('Ngày giao', dateFormat.format(DateTime.parse(order.deliveredAt!).toLocal())),
          ],
          if (order.cancelledAt != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow('Ngày hủy', dateFormat.format(DateTime.parse(order.cancelledAt!).toLocal())),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'pending':
        icon = Icons.hourglass_top_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'confirmed':
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'preparing':
        icon = Icons.inventory_2_outlined;
        color = const Color(0xFF6366F1);
        break;
      case 'shipping':
        icon = Icons.local_shipping_outlined;
        color = const Color(0xFFF97316);
        break;
      case 'delivered':
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF059669);
        break;
      case 'cancelled':
        icon = Icons.cancel_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.receipt_long_rounded;
        color = AppColors.textSecondary;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFD97706);
      case 'confirmed': return const Color(0xFF2563EB);
      case 'preparing': return const Color(0xFF4F46E5);
      case 'shipping': return const Color(0xFFEA580C);
      case 'delivered': return const Color(0xFF059669);
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ITEMS
  // ═══════════════════════════════════════════════════════════
  Widget _buildItemsSection(NumberFormat fmt) {
    final items = _order!.items;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.primaryStart),
              const SizedBox(width: 8),
              Text(
                'Sản phẩm (${items.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 16),
                GestureDetector(
                  onTap: () => _navigateToProduct(item.productId),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFFF3F4F6),
                          child: item.productImageUrl != null && item.productImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.productImageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.textLight, size: 24),
                                )
                              : const Icon(Icons.image_outlined, color: AppColors.textLight, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${fmt.format(item.productPrice)}₫ × ${item.quantity}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Subtotal
                      Text(
                        '${fmt.format(item.subtotal)}₫',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryStart),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ADDRESS
  // ═══════════════════════════════════════════════════════════
  Widget _buildAddressSection() {
    final addr = _order!.shippingAddress!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text(addr.recipientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Text(addr.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            addr.fullAddress,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PAYMENT & NOTE
  // ═══════════════════════════════════════════════════════════
  Widget _buildPaymentSection() {
    final order = _order!;
    final configProvider = context.read<ConfigProvider>();
    String paymentText;
    IconData paymentIcon;
    switch (order.paymentMethod) {
      case 'bank_transfer':
        paymentText = 'Chuyển khoản ngân hàng';
        paymentIcon = Icons.account_balance_rounded;
        break;
      default:
        paymentText = 'Thanh toán khi nhận hàng (COD)';
        paymentIcon = Icons.payments_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method
          Row(
            children: [
              Icon(paymentIcon, size: 20, color: const Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              const Text('Thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paymentText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                _buildPaymentStatusBadge(order.paymentStatus, order.paymentMethod),
              ],
            ),
          ),
          // Bank info when bank_transfer + pending
          if (order.paymentMethod == 'bank_transfer' && order.paymentStatus == 'pending' && configProvider.bankInfo != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF0EA5E9)),
                      SizedBox(width: 8),
                      Text('Thông tin chuyển khoản', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0369A1))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBankRow('Ngân hàng', configProvider.bankInfo!['bankName'] ?? ''),
                  _buildBankRow('Số TK', configProvider.bankInfo!['accountNumber'] ?? '', copyable: true),
                  _buildBankRow('Chủ TK', configProvider.bankInfo!['accountHolder'] ?? ''),
                  if (configProvider.bankInfo!['branch'] != null)
                    _buildBankRow('Chi nhánh', configProvider.bankInfo!['branch']),
                  const SizedBox(height: 6),
                  const Text('💡 Nội dung CK: Ghi SĐT của bạn', style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
          // Note
          if (order.note != null && order.note!.isNotEmpty) ...[
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
              child: Text(
                order.note!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status, String paymentMethod) {
    Color bgColor;
    Color textColor;
    String text;

    // COD + pending → "Thanh toán khi nhận hàng" thay vì "Chờ thanh toán"
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
  // SUMMARY
  // ═══════════════════════════════════════════════════════════
  Widget _buildSummarySection(NumberFormat fmt) {
    final order = _order!;
    final isFreeShip = order.shippingFee == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tiền hàng (${order.items.length} SP)', '${fmt.format(order.subtotal)}₫'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Phí giao hàng',
            isFreeShip ? 'Miễn phí' : '${fmt.format(order.shippingFee)}₫',
            valueColor: isFreeShip ? const Color(0xFF059669) : null,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(
                '${fmt.format(order.total)}₫',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryStart),
              ),
            ],
          ),
        ],
      ),
    );
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
  // CANCEL BUTTON
  // ═══════════════════════════════════════════════════════════
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirmCancel(),
        icon: const Icon(Icons.cancel_outlined, size: 20),
        label: const Text('Hủy đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đơn hàng?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn hủy đơn ${_order!.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final orderProvider = context.read<OrderProvider>();
              final success = await orderProvider.cancelOrder(_order!.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã hủy đơn hàng thành công'), backgroundColor: Color(0xFF059669)),
                );
                _loadOrder(_order!.id); // Reload to update status
              }
            },
            child: const Text('Hủy đơn', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDeliveryButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _confirmDelivery(),
        icon: const Icon(Icons.check_circle_rounded, size: 22),
        label: const Text('Đã nhận hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  void _confirmDelivery() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận nhận hàng?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn đã nhận được hàng từ đơn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chưa', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final orderProvider = context.read<OrderProvider>();
              final success = await orderProvider.confirmDelivery(_order!.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Cảm ơn bạn đã xác nhận!'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                _loadOrder(_order!.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Đã nhận'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (copyable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã copy mã đơn hàng'), duration: Duration(seconds: 1)),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryStart),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBankRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã copy số tài khoản'), duration: Duration(seconds: 1)),
                );
              },
              child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0EA5E9)),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _confirmPayment(),
        icon: const Icon(Icons.check_circle_rounded, size: 22),
        label: const Text('Đã chuyển khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  void _confirmPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận đã chuyển khoản?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn đã chuyển khoản thanh toán cho đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chưa', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final orderProvider = context.read<OrderProvider>();
              final success = await orderProvider.confirmPayment(_order!.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Đã xác nhận chuyển khoản!'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                _loadOrder(_order!.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Đã chuyển'),
          ),
        ],
      ),
    );
  }
}
