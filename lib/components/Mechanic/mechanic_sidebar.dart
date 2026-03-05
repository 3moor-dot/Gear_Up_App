import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MachineDrawer extends StatefulWidget {
  final String currentRoute;

  const MachineDrawer({super.key, required this.currentRoute});

  @override
  State<MachineDrawer> createState() => _MachineDrawerState();
}

class _MachineDrawerState extends State<MachineDrawer> {
  String _userName = "...";
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // ======= جلب بيانات المستخدم (Fetch Profile) =======
  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      if (token == null) return;

      final response = await http.get(
        Uri.parse("http://gearupapp.runasp.net/api/users/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}".trim();
          _photoUrl = data['profilePhotoUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching drawer profile: $e");
    }
  }

  // ======= تسجيل الخروج (Logout) =======
  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // مسح التوكن وكل البيانات المخزنة
    
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F1323) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30), // ليتناسب مع RTL
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 40),
            child: Text(
              "GearUp",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 1.5,
              ),
            ),
          ),

          // Navigation Items (Same as React Sidebar Items)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(context, "لوحة التحكم", Icons.dashboard_rounded, '/mechanic/dashboard', primaryColor, isDark),
                _buildMenuItem(context, "جدول المواعيد", Icons.calendar_today_rounded, '/mechanic/schedule', primaryColor, isDark),
                _buildMenuItem(context, "الحجوزات", Icons.assignment_rounded, '/mechanic/booking', primaryColor, isDark),
                _buildMenuItem(context, "المراجعات", Icons.comment_bank_rounded, '/mechanic/reviewing', primaryColor, isDark),
              ],
            ),
          ),

          // User Profile Card (Bottom Section)
          _buildUserCard(context, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String label, IconData icon, String path, Color primary, bool isDark) {
    final bool isActive = widget.currentRoute == path;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: ListTile(
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isActive) Navigator.pushNamed(context, path);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        selected: isActive,
        selectedTileColor: isDark ? primary.withOpacity(0.1) : const Color(0xFFEAF4FF),
        leading: Icon(
          icon,
          color: isActive ? primary : (isDark ? Colors.white54 : Colors.blueGrey),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? primary : (isDark ? Colors.white70 : Colors.blueGrey[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, bool isDark, Color primary) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? primary.withOpacity(0.1) : const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primary.withOpacity(0.2),
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null ? Icon(Icons.person, color: primary) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "ميكانيكي",
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Settings Button
          _buildActionBtn(
            label: "الإعدادات",
            icon: Icons.settings_rounded,
            color: isDark ? Colors.white10 : Colors.white,
            textColor: isDark ? Colors.white : primary,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/mechanics/machineprofile');
            },
          ),
          const SizedBox(height: 8),
          // Logout Button
          _buildActionBtn(
            label: "تسجيل خروج",
            icon: Icons.logout_rounded,
            color: Colors.transparent,
            textColor: Colors.redAccent,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    // نستخدم ValueNotifier للتحكم في حالة اللمس محلياً لكل زر
    ValueNotifier<bool> isPressed = ValueNotifier(false);

    return ValueListenableBuilder(
      valueListenable: isPressed,
      builder: (context, pressed, child) {
        return GestureDetector(
          onTapDown: (_) => isPressed.value = true,
          onTapUp: (_) => isPressed.value = false,
          onTapCancel: () => isPressed.value = false,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              // تغيير اللون والظل عند الضغط (تأثير الـ Hover في الموبايل)
              color: pressed ? textColor.withOpacity(0.2) : color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: pressed 
                ? [] 
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة تتحرك قليلاً عند الضغط
                AnimatedScale(
                  scale: pressed ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(icon, size: 18, color: textColor),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}