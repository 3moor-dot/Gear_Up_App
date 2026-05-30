import 'package:flutter/material.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';
import 'package:gear_up_app/main.dart'; 
import 'package:provider/provider.dart';
import 'package:gear_up_app/pages/Notification/notification_service.dart'; // تأكد من صحة مسار السيرفيس عندك

class MachineHeader extends StatelessWidget {
  const MachineHeader({super.key});

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
              // اليمين: جرس التنبيهات الذكي وزر الثيم
              Row(
                children: [
                  MechanicNotificationBell(isDark: isDark), // جرس الإشعارات لايف للميكانيكي
                  const SizedBox(width: 8),
                  ThemeToggle(
                    isDark: themeProvider.isDark,
                    onToggle: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              
              // اليسار: العنوان وزر القائمة
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
                  
                  // يظهر فقط في الشاشات الصغيرة لفتح الـ Sidebar
                  if (!isLargeScreen)
                    Builder(
                      builder: (context) => InkWell(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 45, height: 45,
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

// 🔥 الـ Widget الجديد الخاص بجرس الميكانيكي بعد بنائه بالـ Consumer لاحتساب العدد لايف
class MechanicNotificationBell extends StatelessWidget {
  final bool isDark;

  const MechanicNotificationBell({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // التوجيه لصفحة الإشعارات الموحدة المسجلة في الـ routes
        Navigator.pushNamed(context, '/notification');
      },
      child: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          // قراءة عدد الإشعارات الخاص بالميكانيكي مباشرة من الـ List في السيرفيس
          final int notificationCount = notificationService.notifications.length;

          return Stack(
            clipBehavior: Clip.none, // لمنع قص أطراف البادج الأحمر
            children: [
              // شكل الزر الخلفي للجرس
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
              
              // يظهر البادج فقط لو فيه إشعارات فعلياً أكبر من صفر
              if (notificationCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      // إطار جانبي شيك يفصل البادج عن لون كارت الجرس
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F1323) : Colors.white, 
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        // لو الإشعارات كتيرة جداً، يعرض +99 كشكل احترافي
                        notificationCount > 99 ? '+99' : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
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