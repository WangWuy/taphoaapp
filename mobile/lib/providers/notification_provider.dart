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
      // unreadCount is in the response root
      if (response.pagination != null) {
        // Check for unreadCount in the raw response
      }
    }

    // Also get unread count from response
    _unreadCount = _notifications.where((n) => !n.isRead).length;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await _api.patch('${ApiConstants.notifications}/$notificationId/read');
    if (response.success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Replace with updated version
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          referenceType: _notifications[index].referenceType,
          referenceId: _notifications[index].referenceId,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: _notifications[index].createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final response = await _api.patch('${ApiConstants.notifications}/read-all');
    if (response.success) {
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        type: n.type,
        referenceType: n.referenceType,
        referenceId: n.referenceId,
        isRead: true,
        readAt: DateTime.now(),
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }
}
