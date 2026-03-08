import 'package:intl/intl.dart';

class AppFormatter {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  /// Format tiền tệ VNĐ: 150000 → "150,000₫"
  static String currency(num amount) => '${_currencyFormat.format(amount)}₫';

  /// Format tiền tệ không có ₫: 150000 → "150,000"
  static String number(num amount) => _currencyFormat.format(amount);

  /// Format ngày: DateTime → "08/03/2026"
  static String date(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  /// Format ngày giờ: DateTime → "08/03/2026 14:30"
  static String dateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  /// Format thời gian tương đối: "5 phút trước", "2 giờ trước"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Format phone: 0901234567 → "090 123 4567"
  static String phone(String? phone) {
    if (phone == null || phone.length < 10) return phone ?? '';
    return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
  }
}
