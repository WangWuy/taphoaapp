import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.notifications);
    if (response.success && response.data != null) {
      _notifications = (response.data as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
    }

    _unreadCount = _notifications.where((n) => !n.isRead).length;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await _api.patch('${ApiConstants.notifications}/$notificationId/read');
    if (response.success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final response = await _api.patch('${ApiConstants.notifications}/read-all');
    if (response.success) {
      _notifications = _notifications.map((n) => n.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }
}
