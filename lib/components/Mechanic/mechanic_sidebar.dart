import 'package:flutter/material.dart';

class MachineDrawer extends StatelessWidget {
  final String currentRoute;

  const MachineDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    final List<Map<String, dynamic>> menuItems = [
      {'name': 'لوحة التحكم', 'icon': Icons.dashboard_rounded, 'path': '/mechanic/dashboard'},
      {'name': 'جدول المواعيد', 'icon': Icons.calendar_today_rounded, 'path': '/mechanic/schedule'},
      {'name': 'الحجوزات', 'icon': Icons.assignment_rounded, 'path': '/mechanic/booking'},
      {'name': 'المراجعات', 'icon': Icons.comment_bank_rounded, 'path': '/mechanic/reviewing'},
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
                    if (MediaQuery.of(context).size.width <= 1024) Navigator.pop(context);
                    if (!isActive) Navigator.pushNamed(context, item['path']);
                  },
                );
              },
            ),
          ),

          // Mechanic Profile Section (Bottom)
          _buildProfileSection(context, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
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
        selected: isActive,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        selectedTileColor: isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.1),
        leading: Icon(
          icon,
          color: isActive ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[700]),
          size: 24,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            color: isActive ? primaryColor : (isDark ? Colors.grey[300] : Colors.grey[800]),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
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
                radius: 22,
                backgroundImage: AssetImage('assets/mechanic-avatar.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "أحمد الميكانيكي",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text("مدير الورشة", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionBtn(
            context,
            icon: Icons.settings_outlined,
            label: "الإعدادت",
            path: '/mechanics/machineprofile',
            isDark: isDark,
            primaryColor: primaryColor,
            onTap: () {
              if (MediaQuery.of(context).size.width <= 1024) Navigator.pop(context);
              if (currentRoute != '/mechanics/machineprofile') {
                Navigator.pushNamed(context, '/mechanics/machineprofile');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildActionBtn(
            context,
            icon: Icons.logout_rounded,
            label: "تسجيل خروج",
            path: '',
            isDark: isDark,
            primaryColor: primaryColor,
            isLogout: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final bool isActive = currentRoute == path;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.1)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isActive ? primaryColor : (isLogout ? Colors.redAccent : (isDark ? Colors.grey[400] : Colors.grey[700]))),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? primaryColor : (isLogout ? Colors.redAccent : (isDark ? Colors.grey[300] : Colors.grey[800])),
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF137FEC), shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}