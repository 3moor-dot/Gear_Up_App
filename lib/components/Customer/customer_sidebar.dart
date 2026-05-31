import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  final String currentRoute;

  const CustomDrawer({super.key, required this.currentRoute});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSidebarProfile();
  }

  // دالة جلب البيانات من السيرفر (نفس منطق fetchSidebarProfile)
  Future<void> _fetchSidebarProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/users/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          userData = data;
          isLoading = false;
        });

        await prefs.setString('userData', jsonEncode(data));
      } else {
        _loadLocalData(prefs);
      }
    } catch (e) {
      _loadLocalData(prefs);
    }
  }

  void _loadLocalData(SharedPreferences prefs) {
    final savedData = prefs.getString('userData');

    if (savedData != null) {
      if (!mounted) return;

      setState(() {
        userData = jsonDecode(savedData);
        isLoading = false;
      });
    }
  }

  // منطق تسجيل الخروج
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('userData');
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    final List<Map<String, dynamic>> menuItems = [
      {
        'name': 'لوحة التحكم',
        'icon': Icons.dashboard_rounded,
        'path': '/customer/dashboard',
      },
      {
        'name': 'تذكير',
        'icon': Icons.notifications_active_rounded,
        'path': '/customer/reminders',
      },
      {
        'name': 'تاريخ الخدمة',
        'icon': Icons.history_rounded,
        'path': '/customer/servicehistory',
      },
      {
        'name': 'حجز صيانة',
        'icon': Icons.build_circle_rounded,
        'path': '/customer/bookings',
      },
      {
        'name': 'طلب صيانة',
        'icon': Icons.access_time_filled_rounded,
        'path': '/customer/request',
      },
      {
        'name': 'المساعد الذكي',
        'icon': Icons.smart_toy_rounded,
        'path': '/customer/chatbot'
      },
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
            padding: const EdgeInsets.only(top: 60, bottom: 20),
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
                final bool isActive = widget.currentRoute == item['path'];

                return _buildMenuItem(
                  context,
                  name: item['name'],
                  icon: item['icon'],
                  isActive: isActive,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isActive) Navigator.pushNamed(context, item['path']);
                  },
                );
              },
            ),
          ),

          // Profile Section (مطابق تماماً لتصميم React)
          _buildProfileSection(context, isDark, primaryColor),
        ],
      ),
    );
  }

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
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        selected: isActive,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        selectedTileColor: isDark
            ? primaryColor.withOpacity(0.1)
            : const Color(0xFFE5F1FD),
        leading: Icon(
          icon,
          color: isActive ? primaryColor : Colors.grey,
          size: 22,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 15,
            color: isActive
                ? primaryColor
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final String fullName = userData != null
        ? "${userData!['firstName']} ${userData!['lastName']}"
        : "تحميل...";
    final String role = userData?['role'] == 1 ? "حساب عميل" : "حساب مستخدم";
    final String? photoUrl = userData?['profilePhotoUrl'];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? primaryColor.withOpacity(0.05)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // قسم الصورة (نفس منطق React مع fallback للأول من الاسم)
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildInitial(fullName, primaryColor),
                        )
                      : _buildInitial(fullName, primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      role,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionBtn(
            context,
            icon: Icons.settings_rounded,
            label: "الإعدادات",
            isActive: widget.currentRoute == '/customer/profilesettings',
            isDark: isDark,
            primaryColor: primaryColor,
            onTap: () {
              Navigator.pop(context);
              if (widget.currentRoute != '/customer/profilesettings') {
                Navigator.pushNamed(context, '/customer/profilesettings');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildActionBtn(
            context,
            icon: Icons.logout_rounded,
            label: "تسجيل خروج",
            isActive: false,
            isDark: isDark,
            primaryColor: primaryColor,
            isLogout: true,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name, Color primaryColor) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "U",
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? primaryColor.withOpacity(0.15)
                    : const Color(0xFFE5F1FD))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? primaryColor
                  : (isLogout ? Colors.redAccent : Colors.grey),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? primaryColor
                    : (isLogout
                          ? Colors.redAccent
                          : (isDark ? Colors.grey[300] : Colors.grey[700])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
