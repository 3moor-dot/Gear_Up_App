import 'package:flutter/material.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';

class MachineSidebar extends StatefulWidget {
  final String currentRoute;
  final VoidCallback onThemeToggle; 

  const MachineSidebar({
    super.key,
    required this.currentRoute,
    required this.onThemeToggle,
  });

  @override
  State<MachineSidebar> createState() => _MachineSidebarState();
}

class _MachineSidebarState extends State<MachineSidebar> {
  @override
  Widget build(BuildContext context) {
    // استدعاء حالة الدارك مود من ثيم التطبيق مباشرة
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);
    final bool isLargeScreen = MediaQuery.of(context).size.width > 1024;

    Widget sidebarContent = Container(
      width: 280,
      // استخدام ألوان متغيرة بناءً على isDark
      color: isDark ? const Color(0xFF0F1323) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 40),
            child: Text(
              "GearUp",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  label: "لوحة التحكم",
                  route: "/mechanics/machinedashboard",
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                _buildMenuItem(
                  icon: Icons.calendar_today_rounded,
                  label: "جدول المواعيد",
                  route: "/mechanics/schedule",
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                _buildMenuItem(
                  icon: Icons.assignment_rounded,
                  label: "الحجوزات",
                  route: "/mechanics/booking",
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                _buildMenuItem(
                  icon: Icons.comment_bank_rounded,
                  label: "المراجعات",
                  route: "/mechanics/reviewing",
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),

          // Profile & Settings Section (Bottom)
          _buildProfileSection(context, isDark, primaryColor),
        ],
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isLargeScreen 
          ? sidebarContent 
          : Drawer(
              backgroundColor: isDark ? const Color(0xFF0F1323) : Colors.white,
              child: sidebarContent,
            ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String route,
    required bool isDark,
    required Color primaryColor,
  }) {
    bool isActive = widget.currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          if (!isActive) {
            if (MediaQuery.of(context).size.width <= 1024) Navigator.pop(context);
            Navigator.pushNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        selected: isActive,
        selectedTileColor: isDark
            ? primaryColor.withOpacity(0.1)
            : const Color(0xFFE5F1FD),
        leading: Icon(
          icon,
          color: isActive ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? primaryColor : (isDark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? primaryColor.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/avatar-path.png'),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mechanic Name",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Mechanic Account",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // زر تبديل الثيم
          ThemeToggle(isDark: isDark, onToggle: widget.onThemeToggle),
          
          const SizedBox(height: 12),
          
          _buildActionBtn(
            icon: Icons.settings_outlined,
            label: "الإعدادات",
            color: isDark ? Colors.grey[300]! : Colors.grey[800]!,
            onTap: () => Navigator.pushNamed(context, '/mechanics/machineprofile'),
          ),
          _buildActionBtn(
            icon: Icons.logout_rounded,
            label: "تسجيل خروج",
            color: Colors.redAccent,
            onTap: () {
              // منطق تسجيل الخروج هنا
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}