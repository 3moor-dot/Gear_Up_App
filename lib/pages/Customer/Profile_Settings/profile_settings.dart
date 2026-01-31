import 'package:flutter/material.dart';
// استيراد المكونات المشتركة
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

import './personal_data.dart';
import './my_car.dart';
import './security_settings.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // الحالة للتحكم في التبويب النشط (1: البيانات، 2: سيارتي، 3: الحماية)
  int _activeTab = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      // Drawer من جهة اليمين كما في MaintenanceRequestPage
      endDrawer: const CustomDrawer(currentRoute: '/profile'),
      body: SafeArea(
        child: Column(
          children: [
            // الهيدر العلوي المشترك
            const DashboardHeader(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. عنوان الصفحة والمؤشر العلوي (بنمط مشابه للبروجرس)
                    _buildTopHeader(primaryColor, isDark),

                    const SizedBox(height: 30),

                    // 2. أزرار التبديل (Tabs) بتصميم الموبايل
                    _buildTabSwitcher(primaryColor, isDark),

                    const SizedBox(height: 30),

                    // 3. عرض المحتوى بناءً على التبويب المختار
                    _buildActiveTabContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الجزء العلوي الخاص بالعنوان
  Widget _buildTopHeader(Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          decoration: BoxDecoration(
            color: isDark ? primaryColor.withOpacity(0.1) : primaryColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              if (!isDark) BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10)
            ],
          ),
          child: const Text(
            "ملفك الشخصي",
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
      ],
    );
  }

  // أزرار التبديل بين الأقسام
  Widget _buildTabSwitcher(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _tabButton(1, "البيانات الشخصية", primaryColor),
          _tabButton(2, "سيارتي", primaryColor),
          _tabButton(3, "الحماية", primaryColor),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, Color primaryColor) {
    bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // دالة اختيار المحتوى
  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 1:
        return const PersonalDataTab();
      case 2:
        return const MyCarsTab();
      case 3:
        return const SecuritySettingsTab();
      default:
        return const PersonalDataTab();
    }
  }
}