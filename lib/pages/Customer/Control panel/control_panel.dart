import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: '/customer/dashboard'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(), // الهيدر الذي صممناه سابقاً
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Text
                  _buildSectionHeader("أهلاً بعودتك يا جون!", "إليك نظرة عامة سريعة على حالة سيارتك.", isDark),
                  
                  const SizedBox(height: 20),

                  // 1. Car Card
                  _buildCarCard(primaryColor, isDark),

                  const SizedBox(height: 24),

                  // 2. Upcoming Maintenance
                  _buildUpcomingMaintenance(primaryColor, isDark),

                  const SizedBox(height: 24),

                  // 3. Find a Mechanic (Horizontal Scroll)
                  _buildMechanicsSection(primaryColor, isDark),

                  const SizedBox(height: 24),

                  // 4. Service History
                  _buildServiceHistory(primaryColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSectionHeader(String title, String subTitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(subTitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  Widget _buildCarCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("2022 Toyota RAV4", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic)),
                const Text("VIN: JTMRDMBA0N0...", style: TextStyle(fontSize: 9, color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text("تبديل", style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            ),
          ),
          Expanded(
            child: Image.asset('assets/car_rav4.png', height: 100, fit: BoxFit.fitWidth),
          ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildUpcomingMaintenance(Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleWithUnderline("الصيانة القادمة", primaryColor),
        const SizedBox(height: 15),
        _maintenanceItem("تغيير الزيت", "15 ديسمبر 2023", Icons.oil_barrel, primaryColor, isDark),
        const SizedBox(height: 10),
        _maintenanceItem("دوران الإطارات", "20 ديسمبر 2023", Icons.tire_repair, primaryColor, isDark),
      ],
    );
  }

  Widget _buildMechanicsSection(Color primaryColor, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("العثور على ميكانيكي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(onPressed: () {}, child: const Text("عرض الكل", style: TextStyle(fontSize: 12))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            reverse: true, // ليدعم الـ RTL
            children: [
              _mechanicCircle("خبراء العناية", "4.9", primaryColor, isDark),
              _mechanicCircle("لحن الدقة", "4.7", primaryColor, isDark),
              _mechanicCircle("المهندس", "4.8", primaryColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHistory(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("تاريخ الخدمة", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("عرض الكل", style: TextStyle(fontSize: 10, color: Colors.blue, decoration: TextDecoration.underline)),
            ],
          ),
          const SizedBox(height: 15),
          _historyItem("استبدال وسادة الفرامل", "25 أكتوبر - \$250", Icons.settings_backup_restore, isDark),
          _historyItem("تغيير الفلتر", "10 أكتوبر - \$50", Icons.filter_alt, isDark),
        ],
      ),
    );
  }

  // --- Small Helper Widgets ---

  Widget _titleWithUnderline(String title, Color color) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: 2))),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _maintenanceItem(String title, String date, IconData icon, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF93C5FD),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: primaryColor, child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mechanicCircle(String name, String rate, Color primaryColor, bool isDark) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text("⭐ $rate", style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(String title, String desc, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}