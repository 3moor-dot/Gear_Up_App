import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';
import 'package:gear_up_app/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isLargeScreen = MediaQuery.of(context).size.width > 1024;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1323) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الجهة اليمنى
              Row(
                children: [
                  NotificationBell(isDark: isDark),
                  const SizedBox(width: 8),
                  ThemeToggle(
                    isDark: themeProvider.isDark,
                    onToggle: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              Row(
                children: [
                  if (MediaQuery.of(context).size.width > 360)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "لوحة التحكم",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "GearUp Mechanic",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  const SizedBox(width: 12),

                  if (!isLargeScreen)
                    Builder(
                      builder: (context) => InkWell(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.menu_open_rounded,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
        ],
      ),
    );
  }
}

class NotificationBell extends StatefulWidget {
  final bool isDark;

  const NotificationBell({super.key, required this.isDark});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    String key = token == null
        ? "guest_notifications"
        : "notifications_${token.substring(token.length - 10)}";

    final saved = prefs.getString(key);

    if (saved != null) {
      final list = jsonDecode(saved);
      if (!mounted) return;
      setState(() {
        notificationCount = list.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // فتح صفحة الإشعارات
        Navigator.pushNamed(context, "/customer/notifications")
            .then((_) => _loadNotifications()); // إعادة التحميل بعد العودة
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 22,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (notificationCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}