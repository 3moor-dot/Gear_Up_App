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
          // القسم العلوي: البروفايل، التنبيهات، والثيم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // اليمين: التنبيهات والوضع الليلي
              Row(
                children: [
                  _buildIconButton(Icons.notifications_none_outlined, isDark),
                  const SizedBox(width: 8),
                  // الثيم توجل اللي صنعناه سابقاً
                  ThemeToggle(
                    isDark: themeProvider.isDark,
                    onToggle: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              // اليسار: معلومات المستخدم والصورة
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "أهلاً، علي جمال",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "طاب يومك!",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // نستخدم Builder هنا لتمكين فتح الـ Drawer من داخل المكون
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        // إذا كان تطبيقك يدعم العربية (RTL)، فغالباً ستستخدم openEndDrawer
                        Scaffold.of(context).openEndDrawer();

                        // ملاحظة: إذا كان الـ Drawer يفتح من اليسار، استخدم Scaffold.of(context).openDrawer();
                      },
                      child: _buildProfileAvatar(primaryColor),
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
                  ? const Color(0xFF137FEC).withOpacity(0.1)
                  : const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "ابحث عن قطع الغيار بالاسم أو الرقم...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 13,
                ),
                suffixIcon: Icon(Icons.search, color: primaryColor),
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

  // --- Helpers ---

  Widget _buildIconButton(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildProfileAvatar(Color primaryColor) {
    return MouseRegion(
      cursor: SystemMouseCursors
          .click, // يغير شكل الماوس ليد عند الوقوف عليها (للويندوز والويب)
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withOpacity(0.4),
            width: 2,
          ), // زدنا الشفافية قليلاً
          image: const DecorationImage(
            image: AssetImage('assets/avatar-path.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
