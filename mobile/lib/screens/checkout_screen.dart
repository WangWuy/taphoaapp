import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/address_provider.dart';
import '../providers/config_provider.dart';
import '../models/address.dart';
import '../widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteController = TextEditingController();
  String _paymentMethod = 'cod';
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final config = context.read<ConfigProvider>();
      if (!config.isLoaded) await config.loadConfig();

      if (mounted) {
        await context.read<AddressProvider>().loadAddresses();
      }
      if (mounted) {
        final defaultAddr = context.read<AddressProvider>().defaultAddress;
        if (defaultAddr != null) {
          setState(() => _selectedAddress = defaultAddr);
        }
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final configProvider = context.watch<ConfigProvider>();
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    final double shippingFee = configProvider.calculateShippingFee(cartProvider.totalPrice);
    final bool isFreeShip = shippingFee == 0;
    final double grandTotal = cartProvider.totalPrice + shippingFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Đặt hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: !configProvider.isLoaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Address Section ───────────────────────────
                  _buildSectionTitle('📍 Địa chỉ giao hàng', Icons.location_on_outlined),
                  const SizedBox(height: 8),
                  _buildAddressSelector(addressProvider),

                  const SizedBox(height: 20),

                  // ─── Shipping Fee Info ─────────────────────────
                  _buildSectionTitle('🚚 Phí giao hàng', Icons.local_shipping_outlined),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phí ship:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            Text(
                              isFreeShip ? 'Miễn phí 🎉' : '${currencyFormat.format(shippingFee)}₫',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isFreeShip ? const Color(0xFF059669) : AppColors.textPrimary),
                            ),
                          ],
                        ),
                        if (configProvider.shippingRules.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          ...configProvider.shippingRules.map((rule) {
                            final minOrder = (rule['min_order'] ?? 0).toDouble();
                            final maxOrder = rule['max_order'];
                            final fee = (rule['fee'] ?? 0).toDouble();
                            final isCurrentRule = configProvider.calculateShippingFee(cartProvider.totalPrice) == fee && (
                              (maxOrder == null && cartProvider.totalPrice >= minOrder) ||
                              (maxOrder != null && cartProvider.totalPrice >= minOrder && cartProvider.totalPrice < maxOrder.toDouble())
                            );

                            String rangeText;
                            if (maxOrder == null) {
                              rangeText = 'Đơn ≥ ${currencyFormat.format(minOrder)}₫';
                            } else {
                              rangeText = 'Đơn ${currencyFormat.format(minOrder)}₫ - ${currencyFormat.format(maxOrder)}₫';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(isCurrentRule ? Icons.check_circle_rounded : Icons.circle_outlined, size: 14, color: isCurrentRule ? const Color(0xFF059669) : AppColors.textLight),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rangeText, style: TextStyle(fontSize: 12, color: isCurrentRule ? AppColors.textPrimary : AppColors.textLight, fontWeight: isCurrentRule ? FontWeight.w600 : FontWeight.w400))),
                                  Text(fee == 0 ? 'Miễn phí' : '${currencyFormat.format(fee)}₫', style: TextStyle(fontSize: 12, color: isCurrentRule ? const Color(0xFF059669) : AppColors.textLight, fontWeight: isCurrentRule ? FontWeight.w600 : FontWeight.w400)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Payment Method ────────────────────────────
                  _buildSectionTitle('💳 Phương thức thanh toán', Icons.payment_rounded),
                  const SizedBox(height: 8),
                  _buildPaymentOptions(),

                  if (_paymentMethod == 'bank_transfer' && configProvider.bankInfo != null) ...[
                    const SizedBox(height: 12),
                    _buildBankInfo(configProvider.bankInfo!),
                  ],

                  const SizedBox(height: 20),

                  // ─── Note ──────────────────────────────────────
                  _buildSectionTitle('📝 Ghi chú đơn hàng', Icons.note_alt_outlined),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'VD: Giao luôn / Giao lúc 18h / Gọi trước khi giao...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Summary ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                    child: Column(
                      children: [
                        _buildSummaryRow('Tiền hàng (${cartProvider.totalItemsCount} SP)', '${currencyFormat.format(cartProvider.totalPrice)}₫'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Phí giao hàng', isFreeShip ? 'Miễn phí' : '${currencyFormat.format(shippingFee)}₫', valueColor: isFreeShip ? const Color(0xFF059669) : null),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('${currencyFormat.format(grandTotal)}₫', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryStart)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Xác nhận đặt hàng',
                    onPressed: () => _placeOrder(context, cartProvider, orderProvider, shippingFee),
                    isLoading: orderProvider.isLoading,
                    icon: Icons.check_circle_outline_rounded,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String text, IconData icon) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }

  Widget _buildAddressSelector(AddressProvider addressProvider) {
    if (addressProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryStart));
    }

    if (addressProvider.addresses.isEmpty) {
      return GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, '/address-form');
          if (mounted) {
            await context.read<AddressProvider>().loadAddresses();
            final def = context.read<AddressProvider>().defaultAddress;
            if (def != null) setState(() => _selectedAddress = def);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryStart.withValues(alpha: 0.3), style: BorderStyle.solid), boxShadow: AppColors.cardShadow),
          child: const Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: AppColors.primaryStart),
              SizedBox(width: 12),
              Text('Thêm địa chỉ giao hàng', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...addressProvider.addresses.map((addr) {
          final isSelected = _selectedAddress?.id == addr.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedAddress = addr),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppColors.primaryStart : Colors.transparent, width: 1.5),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primaryStart : AppColors.textLight, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(addr.recipientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(addr.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primaryStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('Mặc định', style: TextStyle(fontSize: 10, color: AppColors.primaryStart, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(addr.fullAddress, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, '/address-form');
            if (mounted) await context.read<AddressProvider>().loadAddresses();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 18, color: AppColors.primaryStart),
                SizedBox(width: 4),
                Text('Thêm địa chỉ mới', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildRadioOption('cod', 'Thanh toán khi nhận hàng (COD)', 'Trả tiền mặt cho shipper', _paymentMethod, (v) => setState(() => _paymentMethod = v!)),
        const SizedBox(height: 8),
        _buildRadioOption('bank_transfer', 'Chuyển khoản ngân hàng', 'Chuyển khoản trước khi giao hàng', _paymentMethod, (v) => setState(() => _paymentMethod = v!)),
      ],
    );
  }

  Widget _buildRadioOption(String value, String title, String subtitle, String groupValue, ValueChanged<String?> onChanged) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primaryStart : Colors.transparent, width: 1.5),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primaryStart : AppColors.textLight, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfo(Map<String, dynamic> bankInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF0EA5E9)),
              SizedBox(width: 8),
              Text('Thông tin chuyển khoản', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0369A1))),
            ],
          ),
          const SizedBox(height: 12),
          _buildBankRow('Ngân hàng', bankInfo['bankName'] ?? 'N/A'),
          _buildBankRow('Số TK', bankInfo['accountNumber'] ?? 'N/A', copyable: true),
          _buildBankRow('Chủ TK', bankInfo['accountHolder'] ?? 'N/A'),
          if (bankInfo['branch'] != null) _buildBankRow('Chi nhánh', bankInfo['branch']),
          const SizedBox(height: 8),
          const Text('💡 Nội dung CK: Ghi SĐT của bạn', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontStyle: FontStyle.italic)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBankRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy số tài khoản'), duration: Duration(seconds: 1)));
              },
              child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0EA5E9)),
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

  Future<void> _placeOrder(BuildContext context, CartProvider cartProvider, OrderProvider orderProvider, double shippingFee) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng'), backgroundColor: AppColors.error));
      return;
    }

    final order = await orderProvider.placeOrder(
      addressId: _selectedAddress!.id,
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      shippingType: 'standard',
    );

    if (order != null && mounted) {
      cartProvider.clearLocal();
      Navigator.pushNamedAndRemoveUntil(context, '/order-success', (route) => route.settings.name == '/home', arguments: order);
    } else if (mounted && orderProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(orderProvider.error!), backgroundColor: AppColors.error));
    }
  }
}
