import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../constants/app_colors.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'order_history_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    OrderHistoryScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<TabSwitchNotification>(
        onNotification: (notification) {
          setState(() => _currentIndex = notification.tabIndex);
          return true;
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
                _buildNavItem(1, Icons.category_rounded, Icons.category_outlined, 'Danh mục'),
                _buildNavItem(2, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Lịch sử'),
                _buildNotificationNavItem(),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outlined, 'Tôi'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNotificationNavItem() {
    final isSelected = _currentIndex == 3;
    final notificationProvider = context.watch<NotificationProvider>();

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 3),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              badges.Badge(
                showBadge: notificationProvider.unreadCount > 0,
                badgeContent: Text(
                  notificationProvider.unreadCount > 99 ? '99+' : '${notificationProvider.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.error,
                  padding: EdgeInsets.all(4),
                ),
                child: Icon(
                  isSelected ? Icons.notifications_rounded : Icons.notifications_outlined,
                  color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Thông báo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryStart : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Notification to switch tabs from child screens
class TabSwitchNotification extends Notification {
  final int tabIndex;
  TabSwitchNotification(this.tabIndex);
}
