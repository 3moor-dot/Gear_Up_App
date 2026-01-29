import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String currentRoute; // لتحديد الصفحة النشطة حالياً

  const CustomDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    // قائمة العناصر
    final List<Map<String, dynamic>> menuItems = [
      {
        'name': 'لوحة التحكم',
        'icon': Icons.dashboard_rounded,
        'path': '/dashboard',
      },
      {
        'name': 'تذكير',
        'icon': Icons.notifications_active_rounded,
        'path': '/reminders',
      },
      {
        'name': 'تاريخ الخدمة',
        'icon': Icons.history_rounded,
        'path': '/service-history',
      },
      {
        'name': 'حجز صيانة',
        'icon': Icons.build_circle_rounded,
        'path': '/bookings',
      },
      {
        'name': 'طلب صيانة',
        'icon': Icons.access_time_filled_rounded,
        'path': '/request',
      },
      {'name': 'المساعد الذكي', 'icon': Icons.smart_toy_rounded, 'path': '/ai'},
    ];

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F1323) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 30),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final bool isActive = currentRoute == item['path'];

                return _buildMenuItem(
                  context,
                  name: item['name'],
                  icon: item['icon'],
                  isActive: isActive,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    // 1. غلق الدرور أولاً
                    Navigator.pop(context);

                    // 2. التحقق إذا كنا في نفس الصفحة لتجنب إعادة تحميلها
                    if (!isActive) {
                      // 3. الانتقال باستخدام الاسم (Named Route)
                      Navigator.pushNamed(context, item['path']);
                    }
                  },
                );
              },
            ),
          ),
          // Profile Section (Bottom)
          _buildProfileSection(context, isDark, primaryColor),
        ],
      ),
    );
  }

  // ويدجت لعنصر القائمة
  Widget _buildMenuItem(
    BuildContext context, {
    required String name,
    required IconData icon,
    required bool isActive,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        selected: isActive,
        selectedTileColor: isDark
            ? const Color(0xFF137FEC).withOpacity(0.1)
            : const Color(0xFFE5F1FD),
        leading: Icon(
          icon,
          color: isActive
              ? primaryColor
              : (isDark ? Colors.grey[400] : Colors.grey[700]),
          size: 24,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? primaryColor
                : (isDark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ),
      ),
    );
  }

  // ويدجت البروفايل في الأسفل
  Widget _buildProfileSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/avatar-path.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Client Name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "Client Account",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionBtn(
            icon: Icons.settings_outlined,
            label: "الإعدادات",
            color: isDark ? Colors.grey[300]! : Colors.grey[800]!,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildActionBtn(
            icon: Icons.logout_rounded,
            label: "تسجيل خروج",
            color: Colors.redAccent,
            onTap: () {},
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
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
