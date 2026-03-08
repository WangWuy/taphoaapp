import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';
import 'admin_customer_detail_screen.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final params = <String, String>{};
    if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text;

    final response = await _api.get(ApiConstants.adminCustomers, queryParams: params);
    if (response.success && response.data != null) {
      _customers = List<Map<String, dynamic>>.from(response.data);
    }
    setState(() => _isLoading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Khách hàng (${_customers.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm tên, SĐT hoặc email...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _searchCtrl.clear(); _loadCustomers(); })
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
                : _customers.isEmpty
                    ? const Center(child: Text('Không tìm thấy khách hàng', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            final addresses = (customer['addresses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                            final orderCount = customer['orderCount'] ?? 0;

                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminCustomerDetailScreen(customerId: customer['id'])),
                                );
                                _loadCustomers();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primaryStart.withValues(alpha: 0.1),
                                          child: Text((customer['name'] ?? 'K')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryStart, fontSize: 18)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(customer['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                              const SizedBox(height: 2),
                                              Text('📱 ${customer['phone'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
                                          child: Text('$orderCount đơn', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
                                      ],
                                    ),
                                    if (addresses.isNotEmpty) ...[
                                      const Divider(height: 20),
                                      ...addresses.take(1).map((addr) => Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(addr['is_default'] == true ? Icons.star_rounded : Icons.location_on_outlined, size: 16, color: addr['is_default'] == true ? const Color(0xFFF59E0B) : AppColors.textLight),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              [addr['address_line'], addr['ward'], addr['district'], addr['city']].where((s) => s != null && s.toString().isNotEmpty).join(', '),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )),
                                    ],
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: 80 * index), duration: 300.ms);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
