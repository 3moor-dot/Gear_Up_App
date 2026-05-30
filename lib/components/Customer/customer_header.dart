import 'package:flutter/material.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';
import 'package:gear_up_app/main.dart';
import 'package:provider/provider.dart';
import 'package:gear_up_app/pages/Notification/notification_service.dart'; // تأكد من صحة مسار السيرفيس عندك

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
              // الجهة اليمنى: جرس الإشعارات وزر الثيم
              Row(
                children: [
                  NotificationBell(isDark: isDark), // جرس الإشعارات الذكي
                  const SizedBox(width: 8),
                  ThemeToggle(
                    isDark: themeProvider.isDark,
                    onToggle: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              
              // الجهة اليسرى: العنوان والقائمة تظهر حسب الشاشة
              Row(
                children: [
                  if (MediaQuery.of(context).size.width > 360)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "مركز الصيانة",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "إدارة ورشة GearUp",
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
                            border: Border.all(color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.menu_open_rounded, color: primaryColor, size: 28),
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

// 🔥 الـ Widget الخاص بالجرس بعد إعادة بنائه بالـ Consumer لاحتساب العدد لايف
class NotificationBell extends StatelessWidget {
  final bool isDark;

  const NotificationBell({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // الـ Route مسجل في main.dart باسم '/notification'
        Navigator.pushNamed(context, "/notification");
      },
      child: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          // جلب عدد الإشعارات الحالية مباشرة من الـ List اللي جوه السيرفيس
          final int notificationCount = notificationService.notifications.length;

          return Stack(
            clipBehavior: Clip.none, // عشان نضمن إن البادج الأحمر ميتأكلش من الأطراف
            children: [
              // شكل كارت الزر الخلفي للجرس
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: 22,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              
              // عرض الرقم فقط إذا كان هناك إشعارات أكبر من صفر
              if (notificationCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0F1323) : Colors.white, width: 1.5), // إطار شيك يفصل البادج عن الزر
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        // لو الإشعارات كتيرة جداً، اعرض +99 زي التطبيقات الاحترافية
                        notificationCount > 99 ? '+99' : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial', // خط سليم للأرقام الصغيرة
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}