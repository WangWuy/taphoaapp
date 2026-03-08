import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['pending', 'processing', 'delivered', 'cancelled'];
  final _tabLabels = ['Mới', 'Đang xử lý', 'Hoàn thành', 'Đã hủy'];

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  DateTimeRange? _dateRange;
  final ApiService _api = ApiService();
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      _loadCounts();
    });
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadOrders() {
    final tab = _tabs[_tabController.index];
    String status;
    if (tab == 'processing') {
      status = 'confirmed,preparing,shipping';
    } else {
      status = tab;
    }
    context.read<OrderProvider>().loadAdminOrders(
      status: status,
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      dateFrom: _dateRange?.start,
      dateTo: _dateRange?.end,
    );
  }

  Future<void> _loadCounts() async {
    final response = await _api.get('${ApiConstants.adminOrders}/stats/counts');
    if (response.success && response.data != null && mounted) {
      setState(() {
        _counts = {
          'pending': int.tryParse(response.data['pending']?.toString() ?? '0') ?? 0,
          'processing': int.tryParse(response.data['processing']?.toString() ?? '0') ?? 0,
          'delivered': int.tryParse(response.data['delivered']?.toString() ?? '0') ?? 0,
          'cancelled': int.tryParse(response.data['cancelled']?.toString() ?? '0') ?? 0,
        };
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadOrders();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('vi', 'VN'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primaryStart, onPrimary: Colors.white, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadOrders();
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');
    final dateFmt = DateFormat('dd/MM');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Quản lý đơn hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppColors.primaryStart,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryStart,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar + Date filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Tìm mã đơn, tên khách...',
                      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { _searchCtrl.clear(); _loadOrders(); })
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _dateRange != null ? AppColors.primaryStart.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _dateRange != null ? AppColors.primaryStart : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range_rounded, size: 18, color: _dateRange != null ? AppColors.primaryStart : AppColors.textSecondary),
                        if (_dateRange != null) ...[
                          const SizedBox(width: 6),
                          Text('${dateFmt.format(_dateRange!.start)} - ${dateFmt.format(_dateRange!.end)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryStart)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _clearDateRange,
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryStart),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Counts summary
          if (_counts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: Row(
                children: [
                  _buildCountChip('Mới', _counts['pending'] ?? 0, const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildCountChip('Xử lý', _counts['processing'] ?? 0, AppColors.primaryStart),
                  const SizedBox(width: 8),
                  _buildCountChip('Xong', _counts['delivered'] ?? 0, const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildCountChip('Hủy', _counts['cancelled'] ?? 0, AppColors.textLight),
                ],
              ),
            ),
          // Order list
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
                : orderProvider.adminOrders.isEmpty
                    ? const Center(child: Text('Không có đơn hàng nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)))
                    : RefreshIndicator(
                        onRefresh: () async => _loadOrders(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orderProvider.adminOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = orderProvider.adminOrders[index];
                            return _buildOrderCard(order, currencyFormat, orderProvider, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, NumberFormat fmt, OrderProvider orderProvider, int index) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: order.id)),
        );
        if (result == true) {
          _loadOrders();
          _loadCounts();
        }
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              _buildStatusBadge(order.status, order.statusText),
            ],
          ),
          const SizedBox(height: 8),
          // Customer info
          if (order.customer != null) ...[
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('${order.customer!.name} • ${order.customer!.phone}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
          if (order.shippingAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(order.shippingAddress!.fullAddress, style: const TextStyle(fontSize: 12, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(child: Text('Ghi chú: ${order.note}', style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order.items.length} SP • ${fmt.format(order.total)}₫', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryStart)),
              _buildStatusActions(order, orderProvider),
            ],
          ),
        ],
      ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index), duration: 300.ms);
  }

  Future<void> _onQuickAction(Order order, String nextStatus, String label, OrderProvider orderProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$label đơn hàng?'),
        content: Text('Bạn muốn $label đơn ${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(label),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await orderProvider.updateOrderStatus(order.id, nextStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Đã $label đơn ${order.orderNumber}', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadOrders();
      _loadCounts();
    }
  }

  Widget _buildStatusActions(Order order, OrderProvider orderProvider) {
    String? nextStatus;
    String? nextLabel;
    IconData? nextIcon;
    Color? nextColor;

    switch (order.status) {
      case 'pending':
        nextStatus = 'confirmed'; nextLabel = 'Xác nhận'; nextIcon = Icons.check_rounded; nextColor = const Color(0xFF3B82F6);
        break;
      case 'confirmed':
      case 'preparing': // backward compat
        nextStatus = 'shipping'; nextLabel = 'Giao hàng'; nextIcon = Icons.local_shipping_rounded; nextColor = const Color(0xFFF59E0B);
        break;
      case 'shipping':
        nextStatus = 'delivered'; nextLabel = 'Đã giao'; nextIcon = Icons.check_circle_rounded; nextColor = const Color(0xFF059669);
        break;
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _onQuickAction(order, nextStatus!, nextLabel!, orderProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: nextColor!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nextIcon, size: 16, color: nextColor),
            const SizedBox(width: 4),
            Text(nextLabel!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: nextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String text) {
    Color bgColor; Color textColor;
    switch (status) {
      case 'pending': bgColor = const Color(0xFFFEF3C7); textColor = const Color(0xFF92400E); break;
      case 'confirmed': bgColor = const Color(0xFFDBEAFE); textColor = const Color(0xFF1E40AF); break;
      case 'preparing': bgColor = const Color(0xFFE0E7FF); textColor = const Color(0xFF3730A3); break;
      case 'shipping': bgColor = const Color(0xFFFED7AA); textColor = const Color(0xFF9A3412); break;
      case 'delivered': bgColor = const Color(0xFFD1FAE5); textColor = const Color(0xFF065F46); break;
      case 'cancelled': bgColor = const Color(0xFFFEE2E2); textColor = const Color(0xFF991B1B); break;
      default: bgColor = AppColors.surfaceLight; textColor = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
