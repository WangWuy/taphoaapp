import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/address_provider.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Địa chỉ giao hàng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryStart),
            onPressed: () async {
              await Navigator.pushNamed(context, '/address-form');
              if (mounted) context.read<AddressProvider>().loadAddresses();
            },
          ),
        ],
      ),
      body: addressProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : addressProvider.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, size: 80, color: AppColors.textLight.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('Chưa có địa chỉ nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addressProvider.addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final addr = addressProvider.addresses[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: addr.isDefault ? Border.all(color: AppColors.primaryStart.withValues(alpha: 0.3)) : null,
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(addr.recipientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(width: 8),
                              Text(addr.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const Spacer(),
                              if (addr.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.primaryStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Mặc định', style: TextStyle(fontSize: 11, color: AppColors.primaryStart, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(addr.fullAddress, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (!addr.isDefault)
                                GestureDetector(
                                  onTap: () => addressProvider.setDefault(addr.id),
                                  child: const Text('Đặt mặc định', style: TextStyle(fontSize: 13, color: AppColors.primaryStart, fontWeight: FontWeight.w500)),
                                ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _confirmDelete(context, addr.id, addressProvider),
                                child: const Text('Xóa', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AddressProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa địa chỉ?'),
        content: const Text('Bạn có chắc muốn xóa địa chỉ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () { Navigator.pop(ctx); provider.deleteAddress(id); }, child: const Text('Xóa', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}
