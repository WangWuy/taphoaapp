import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Bank info
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  // Shipping rules
  List<Map<String, dynamic>> _shippingRules = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final response = await _api.get('/config');
    if (response.success && response.data != null) {
      final bank = response.data['bank'] as Map<String, dynamic>? ?? {};
      _bankNameCtrl.text = bank['bankName'] ?? '';
      _accountNumberCtrl.text = bank['accountNumber'] ?? '';
      _accountHolderCtrl.text = bank['accountHolder'] ?? '';
      _branchCtrl.text = bank['branch'] ?? '';

      final shipping = response.data['shipping'] as Map<String, dynamic>? ?? {};
      _shippingRules = List<Map<String, dynamic>>.from(shipping['rules'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final response = await _api.put('/config', body: {
      'bank': {
        'bankName': _bankNameCtrl.text.trim(),
        'accountNumber': _accountNumberCtrl.text.trim(),
        'accountHolder': _accountHolderCtrl.text.trim(),
        'branch': _branchCtrl.text.trim(),
      },
      'shipping': {
        'rules': _shippingRules,
      },
    });

    setState(() => _isSaving = false);

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cài đặt'), backgroundColor: Color(0xFF059669)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Có lỗi xảy ra'), backgroundColor: AppColors.error),
      );
    }
  }

  void _addShippingRule() {
    setState(() {
      _shippingRules.add({'min_order': 0, 'max_order': null, 'fee': 0, 'label': ''});
    });
  }

  void _removeShippingRule(int index) {
    setState(() => _shippingRules.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Cài đặt cửa hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryStart))
                  : const Text('Lưu', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Bank Info ─────────────────────────────
                  _sectionHeader(Icons.account_balance_rounded, 'Thông tin ngân hàng', const Color(0xFF0EA5E9)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tên ngân hàng'),
                        const SizedBox(height: 6),
                        TextFormField(controller: _bankNameCtrl, decoration: _inputDecoration('VD: Vietcombank')),
                        const SizedBox(height: 14),

                        _buildLabel('Số tài khoản'),
                        const SizedBox(height: 6),
                        TextFormField(controller: _accountNumberCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration('1234567890')),
                        const SizedBox(height: 14),

                        _buildLabel('Chủ tài khoản'),
                        const SizedBox(height: 6),
                        TextFormField(controller: _accountHolderCtrl, decoration: _inputDecoration('NGUYEN VAN A'), textCapitalization: TextCapitalization.characters),
                        const SizedBox(height: 14),

                        _buildLabel('Chi nhánh'),
                        const SizedBox(height: 6),
                        TextFormField(controller: _branchCtrl, decoration: _inputDecoration('Chi nhánh...')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ─── Shipping Rules ─────────────────────────
                  _sectionHeader(Icons.local_shipping_rounded, 'Phí giao hàng', const Color(0xFFF59E0B)),
                  const SizedBox(height: 4),
                  const Text('Thiết lập phí ship dựa trên giá trị đơn hàng', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  ..._shippingRules.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final rule = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Mức ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const Spacer(),
                              if (_shippingRules.length > 1)
                                GestureDetector(
                                  onTap: () => _removeShippingRule(idx),
                                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Đơn từ (₫)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      initialValue: '${rule['min_order'] ?? 0}',
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: _inputDecoration('0').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                                      onChanged: (v) => _shippingRules[idx]['min_order'] = int.tryParse(v) ?? 0,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Đơn đến (₫)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      initialValue: rule['max_order'] != null ? '${rule['max_order']}' : '',
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: _inputDecoration('Không giới hạn').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                                      onChanged: (v) => _shippingRules[idx]['max_order'] = v.isEmpty ? null : (int.tryParse(v)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Phí ship (₫)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      initialValue: '${rule['fee'] ?? 0}',
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      decoration: _inputDecoration('0').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                                      onChanged: (v) => _shippingRules[idx]['fee'] = int.tryParse(v) ?? 0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  GestureDetector(
                    onTap: _addShippingRule,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryStart.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryStart.withValues(alpha: 0.3), style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: AppColors.primaryStart, size: 20),
                          SizedBox(width: 6),
                          Text('Thêm mức giá', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
    filled: true,
    fillColor: AppColors.surfaceLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryStart, width: 1.5)),
  );
}
