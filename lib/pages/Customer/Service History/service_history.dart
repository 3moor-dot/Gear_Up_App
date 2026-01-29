import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      // السايد بار (القائمة الجانبية)
      endDrawer: const CustomDrawer(currentRoute: '/service-history'),
      body: SafeArea(
        child: Column(
          children: [
            // الهيدر العلوي المشترك
            const DashboardHeader(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // العنوان العلوي واختيار السيارة بنفس نمط الصفحة السابقة
                  _buildTopHeader(
                    "تاريخ الخدمة",
                    "تتبع أعمال الصيانة والإصلاحات",
                    primaryColor,
                  ),

                  const SizedBox(height: 25),

                  // بطاقات الملخص الإحصائي (أفقية)
                  _buildStatsSection(isDark),

                  const SizedBox(height: 25),

                  // أدوات البحث والفلترة
                  _buildSearchAndFilter(isDark, primaryColor),

                  const SizedBox(height: 25),

                  // قسم سجلات الصيانة
                  _buildSectionTitle("السجلات الأخيرة", primaryColor),
                  const SizedBox(height: 15),

                  // قائمة السجلات المصممة كبطاقات احترافية
                  _buildServiceCard(
                    title: "تغيير زيت المحرك",
                    date: "Oct 26, 2:00 PM",
                    cost: "250 EGP",
                    mechanic: "Alice Martin",
                    icon: Icons.oil_barrel,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  _buildServiceCard(
                    title: "استبدال وسادات الفرامل",
                    date: "Oct 15, 10:30 AM",
                    cost: "850 EGP",
                    mechanic: "Samer John",
                    icon: Icons.settings_input_component,
                    color: Colors.red,
                    isDark: isDark,
                  ),
                  _buildServiceCard(
                    title: "فحص الإطارات المجدول",
                    date: "Sep 20, 4:00 PM",
                    cost: "100 EGP",
                    mechanic: "Alice Martin",
                    icon: Icons.tire_repair,
                    color: Colors.orange,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // زر تصدير البيانات (Export) بنمط جذاب
                  _buildExportPromo(primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components (نفس ستايل الكود الذي أرسلته) ---

  Widget _buildTopHeader(String title, String subtitle, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text(
                "2022 Toyota RAV4",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true, // لدعم الـ RTL
        children: [
          _statCard(
            "الزيارة القادمة",
            "غداً",
            "تغيير زيت",
            Colors.orange,
            isDark,
          ),
          _statCard(
            "الخدمة الأخيرة",
            "25 أكتوبر",
            "استبدال وسادة الفرامل",
            Colors.blue,
            isDark,
          ),
          _statCard(
            "إجمالي الإنفاق",
            "1,245 EGP",
            "↑ 12% مقارنة بالعام الماضي",
            Colors.green,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    String sub,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          Text(
            sub,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "بحث في السجلات...",
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.filter_list, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String date,
    required String cost,
    required String mechanic,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                cost,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    mechanic,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Text(
                "عرض التفاصيل",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportPromo(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.file_download_outlined, color: primaryColor, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "تحميل السجل بالكامل",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Text(
                  "احصل على نسخة PDF من تقرير صيانة سيارتك",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "تحميل",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
