import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/additional_tab.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/personal_tab.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/services_tab.dart';

class MProfilePage extends StatefulWidget {
  const MProfilePage({super.key});

  @override
  State<MProfilePage> createState() => _MProfilePageState();
}

class _MProfilePageState extends State<MProfilePage> {
  String activeTab = "personal";

  final List<Map<String, String>> tabs = [
    {"id": "personal", "label": "البيانات الشخصية"},
    {"id": "additional", "label": "بيانات إضافية"},
    {"id": "services", "label": "الخدمات"},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB),
      // الدرج الجانبي للموبايل
      endDrawer: const MachineDrawer(currentRoute: '/mechanics/machineprofile'),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // الهيدر الذي يحتوي على التنبيهات والتبديل
              const MachineHeader(),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // العنوان
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "ملفك الشخصي",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // التبويبات (Tabs)
                    _buildTabsRow(isDark, primaryColor),

                    const SizedBox(height: 24),

                    // محتوى التبويب النشط
                    _buildTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- شريط التبويبات ---
  Widget _buildTabsRow(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          bool isActive = activeTab == tab['id'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => setState(() => activeTab = tab['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor
                      : (isDark ? const Color(0xFF0D1629) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? primaryColor
                        : (isDark ? Colors.white10 : Colors.grey[300]!),
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Text(
                  tab['label']!,
                  style: TextStyle(
                    color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- تبديل المحتوى ---
  Widget _buildTabContent() {
    switch (activeTab) {
      case "personal":
        return const PersonalTab(); // تأكد من تحويل الـ Component لـ Widget
      case "additional":
        return const AdditionalTab();
      case "services":
        return const ServicesTab();
      default:
        return const SizedBox();
    }
  }
}
