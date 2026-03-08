import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _revenue = {};
  List<dynamic> _topProducts = [];
  Map<String, dynamic> _orderStats = {};
  Map<String, dynamic> _inventory = {};
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _api.get('/admin/reports/revenue', queryParams: {'period': 'daily'}),
      _api.get('/admin/reports/top-products', queryParams: {'limit': '5'}),
      _api.get('/admin/reports/order-stats'),
      _api.get('/admin/reports/inventory-alerts', queryParams: {'threshold': '20'}),
    ]);

    if (mounted) {
      setState(() {
        if (results[0].success) _revenue = results[0].data is Map ? results[0].data : {};
        if (results[1].success) _topProducts = results[1].data is List ? results[1].data : [];
        if (results[2].success) _orderStats = results[2].data is Map ? results[2].data : {};
        if (results[3].success) _inventory = results[3].data is Map ? results[3].data : {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRevenueCards().animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    _buildOrderStatusSection().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    _buildTopProductsSection().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    _buildInventorySection().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueCards() {
    final summary = _revenue['summary'] as Map<String, dynamic>? ?? {};
    final totalRevenue = summary['totalRevenue'] ?? 0;
    final totalOrders = summary['totalOrders'] ?? 0;
    final totalShipping = summary['totalShipping'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💰 Doanh thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        // Main revenue card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.buttonShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng doanh thu', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(_currencyFormat.format(totalRevenue), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniStat('Đơn hàng', '$totalOrders', Icons.shopping_bag_rounded),
                  const SizedBox(width: 20),
                  _miniStat('Phí ship', _currencyFormat.format(totalShipping), Icons.local_shipping_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderStatusSection() {
    final byStatus = _orderStats['byStatus'] as List<dynamic>? ?? [];

    final statusIcons = {
      'pending': '🕐', 'confirmed': '✅', 'preparing': '📦',
      'shipping': '🚚', 'delivered': '🎉', 'cancelled': '❌',
    };
    final statusLabels = {
      'pending': 'Chờ xử lý', 'confirmed': 'Đã xác nhận', 'preparing': 'Đang chuẩn bị',
      'shipping': 'Đang giao', 'delivered': 'Đã giao', 'cancelled': 'Đã hủy',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 Đơn hàng theo trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: byStatus.isEmpty
              ? const Center(child: Text('Chưa có đơn hàng', style: TextStyle(color: AppColors.textSecondary)))
              : Column(
                  children: byStatus.map((item) {
                    final status = item['status'] ?? '';
                    final count = int.tryParse('${item['count']}') ?? 0;
                    final value = int.tryParse('${item['total_value']}') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(statusIcons[status] ?? '📋', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(statusLabels[status] ?? status, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryStart.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryStart)),
                          ),
                          const SizedBox(width: 10),
                          Text(_currencyFormat.format(value), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTopProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏆 Top sản phẩm bán chạy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: _topProducts.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.textSecondary)))
              : Column(
                  children: _topProducts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final medals = ['🥇', '🥈', '🥉'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(i < 3 ? medals[i] : '${i + 1}.', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['product_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('Đã bán: ${p['total_sold']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text(_currencyFormat.format(int.tryParse('${p['total_revenue']}') ?? 0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildInventorySection() {
    final data = _inventory['data'] as List<dynamic>? ?? [];
    final summary = _inventory['summary'] as Map<String, dynamic>? ?? {};
    final outOfStock = summary['outOfStock'] ?? 0;
    final lowStock = summary['lowStock'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚠️ Cảnh báo tồn kho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            if (outOfStock > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Hết: $outOfStock', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
              ),
            const SizedBox(width: 6),
            if (lowStock > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Sắp hết: $lowStock', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_rounded, size: 36, color: AppColors.success),
                SizedBox(height: 8),
                Text('Tồn kho ổn!', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
              ],
            ),
          )
        else
          ...data.take(5).map((item) {
            final isOut = item['alert_type'] == 'out_of_stock';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isOut ? AppColors.error : AppColors.warning).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isOut ? AppColors.error : AppColors.warning).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(isOut ? Icons.error_rounded : Icons.warning_rounded, color: isOut ? AppColors.error : AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('${item['stock_quantity']} ${item['unit'] ?? ''}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isOut ? AppColors.error : AppColors.warning)),
                ],
              ),
            );
          }),
      ],
    );
  }
}
