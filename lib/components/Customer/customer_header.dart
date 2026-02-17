import 'package:flutter/material.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';
import 'package:gear_up_app/main.dart'; 
import 'package:provider/provider.dart';

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
          // القسم العلوي: التنبيهات، الثيم، وزر القائمة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الجهة اليمنى (التنبيهات والوضع الليلي)
              Row(
                children: [
                  _buildIconButton(Icons.notifications_none_outlined, isDark),
                  const SizedBox(width: 8),
                  ThemeToggle(
                    isDark: themeProvider.isDark,
                    onToggle: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              
              // الجهة اليسرى (زر القائمة والترحيب)
              Row(
                children: [
                  // إظهار نص الترحيب فقط إذا كانت الشاشة تسمح
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
                  
                  // زر فتح السايد بار (يظهر غالباً في الموبايل والتابلت)
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
                          child: Icon(
                            Icons.menu_open_rounded, // أيقونة احترافية لفتح القائمة
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

          // القسم السفلي: شريط البحث
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.transparent,
              ),
            ),
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "ابحث عن الحجوزات، العملاء، أو المواعيد...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 13,
                ),
                suffixIcon: Icon(Icons.search_rounded, color: primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت مساعد للأيقونات الصغيرة
  Widget _buildIconButton(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}