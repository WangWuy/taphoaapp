import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import '../../models/order.dart';
import 'admin_order_detail_screen.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const AdminCustomerDetailScreen({super.key, required this.customerId});

  @override
  State<AdminCustomerDetailScreen> createState() => _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _customer;
  List<Order> _orders = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    final response = await _api.get('${ApiConstants.adminCustomers}/${widget.customerId}');
    if (response.success && response.data != null) {
      _customer = Map<String, dynamic>.from(response.data);
      _orders = ((response.data['orders'] as List?) ?? [])
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      _stats = response.data['stats'] as Map<String, dynamic>?;
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Chi tiết khách hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : _customer == null
              ? const Center(child: Text('Không tìm thấy khách hàng', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _loadCustomer,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Profile Card ──────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primaryStart.withValues(alpha: 0.1),
                                child: Text(
                                  (_customer!['name'] ?? 'K')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primaryStart),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_customer!['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    _infoRow(Icons.phone_rounded, _customer!['phone'] ?? ''),
                                    if (_customer!['email'] != null) ...[
                                      const SizedBox(height: 3),
                                      _infoRow(Icons.email_outlined, _customer!['email']),
                                    ],
                                    const SizedBox(height: 3),
                                    _infoRow(
                                      Icons.calendar_today_rounded,
                                      'Tham gia: ${_customer!['created_at'] != null ? dateFormat.format(DateTime.parse(_customer!['created_at']).toLocal()) : 'N/A'}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),

                        const SizedBox(height: 16),

                        // ─── Stats Cards ───────────────────────
                        Row(
                          children: [
                            Expanded(child: _statCard('Tổng đơn', '${_stats?['totalOrders'] ?? 0}', Icons.receipt_long_rounded, const Color(0xFF3B82F6))),
                            const SizedBox(width: 10),
                            Expanded(child: _statCard('Chi tiêu', '${currencyFormat.format(_stats?['totalSpent'] ?? 0)}₫', Icons.attach_money_rounded, const Color(0xFF059669))),
                            const SizedBox(width: 10),
                            Expanded(child: _statCard('Đã hủy', '${_stats?['cancelledOrders'] ?? 0}', Icons.cancel_outlined, AppColors.error)),
                          ],
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                        const SizedBox(height: 24),

                        // ─── Addresses ─────────────────────────
                        _sectionHeader(Icons.location_on_rounded, 'Địa chỉ', const Color(0xFFF59E0B)),
                        const SizedBox(height: 10),
                        ...(_buildAddresses()),

                        const SizedBox(height: 24),

                        // ─── Order History ─────────────────────
                        _sectionHeader(Icons.shopping_bag_rounded, 'Lịch sử đơn hàng (${_orders.length})', const Color(0xFF8B5CF6)),
                        const SizedBox(height: 10),
                        if (_orders.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                          )
                        else
                          ..._orders.asMap().entries.map((entry) => _buildOrderCard(entry.value, currencyFormat, dateFormat, entry.key)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  List<Widget> _buildAddresses() {
    final addresses = (_customer?['addresses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (addresses.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
          child: const Center(child: Text('Chưa có địa chỉ nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
        ),
      ];
    }
    return addresses.asMap().entries.map((entry) {
      final addr = entry.value;
      final idx = entry.key;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                addr['is_default'] == true ? Icons.star_rounded : Icons.location_on_outlined,
                size: 18,
                color: addr['is_default'] == true ? const Color(0xFFF59E0B) : AppColors.textLight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${addr['recipient_name']} • ${addr['phone']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      [addr['address_line'], addr['ward'], addr['district'], addr['city']]
                          .where((s) => s != null && s.toString().isNotEmpty)
                          .join(', '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 80 * idx), duration: 250.ms),
      );
    }).toList();
  }

  Widget _buildOrderCard(Order order, NumberFormat fmt, DateFormat dateFmt, int index) {
    Color statusBg;
    Color statusText;
    switch (order.status) {
      case 'pending': statusBg = const Color(0xFFFEF3C7); statusText = const Color(0xFF92400E); break;
      case 'confirmed': statusBg = const Color(0xFFDBEAFE); statusText = const Color(0xFF1E40AF); break;
      case 'preparing': statusBg = const Color(0xFFE0E7FF); statusText = const Color(0xFF3730A3); break;
      case 'shipping': statusBg = const Color(0xFFFED7AA); statusText = const Color(0xFF9A3412); break;
      case 'delivered': statusBg = const Color(0xFFD1FAE5); statusText = const Color(0xFF065F46); break;
      case 'cancelled': statusBg = const Color(0xFFFEE2E2); statusText = const Color(0xFF991B1B); break;
      default: statusBg = AppColors.surfaceLight; statusText = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: order.id)));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(order.statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusText)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.items.length} SP • ${fmt.format(order.total)}₫', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryStart)),
                  if (order.createdAt != null)
                    Text(dateFmt.format(DateTime.parse(order.createdAt!).toLocal()), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index), duration: 250.ms);
  }
}
