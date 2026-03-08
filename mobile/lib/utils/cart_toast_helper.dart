import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CartToastHelper {
  static void show(BuildContext context, {
    required bool success,
    required String productName,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success
                    ? 'Đã thêm $productName vào giỏ'
                    : 'Không thể thêm $productName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
