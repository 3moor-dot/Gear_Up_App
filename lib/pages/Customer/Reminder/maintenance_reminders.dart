import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

class MaintenanceRemindersPage extends StatefulWidget {
  const MaintenanceRemindersPage({super.key});

  @override
  State<MaintenanceRemindersPage> createState() =>
      _MaintenanceRemindersPageState();
}

class _MaintenanceRemindersPageState extends State<MaintenanceRemindersPage> {
  int _activeTab = 0; // 0: الجميع, 1: تأخرت, 2: القادمة

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: '/reminders'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header Section
                  _buildTopHeader(primaryColor, isDark),

                  const SizedBox(height: 25),

                  // Tabs & Add Button
                  _buildTabsAndAddAction(primaryColor, isDark),

                  const SizedBox(height: 25),

                  // High Priority Alert Card (Warning Card)
                  _buildCriticalAlertCard(isDark),

                  const SizedBox(height: 25),

                  // Upcoming Tasks List
                  _buildSectionTitle("المهام القادمة", primaryColor),
                  const SizedBox(height: 15),
                  _buildTaskItem(
                    "تغيير الزيت",
                    "12 نوفمبر",
                    "🛢️",
                    Colors.blue,
                    isDark,
                  ),
                  _buildTaskItem(
                    "دوران الإطارات",
                    "15 نوفمبر",
                    "🛞",
                    Colors.orange,
                    isDark,
                  ),
                  _buildTaskItem(
                    "التفتيش الحكومي",
                    "20 نوفمبر",
                    "🚗",
                    Colors.red,
                    isDark,
                  ),

                  const SizedBox(height: 30),

                  // Completed History
                  _buildCompletedHistory(primaryColor, isDark),

                  const SizedBox(height: 25),

                  // Custom Reminders Promo Card
                  _buildCustomReminderPromo(primaryColor),

                  const SizedBox(height: 25),

                  // Mechanic Contact Card
                  _buildMechanicContactCard(primaryColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildTopHeader(Color primaryColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "تذكيرات الصيانة",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "إدارة مهام سيارتك",
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabsAndAddAction(Color primaryColor, bool isDark) {
    List<String> tabs = ["الجميع", "تأخرت", "القادمة"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Custom Tabs
        Row(
          children: List.generate(tabs.length, (index) {
            bool isActive = _activeTab == index;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        // Add Button
        CircleAvatar(
          backgroundColor: primaryColor,
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalAlertCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1515) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "⚠️ مطلوب الانتباه",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Icon(
                Icons.more_horiz,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "تغيير سائل الفرامل",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "يوصى بالإجراء كل سنتين أو 30 ألف ميل",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  "حدد موعداً آخر",
                  Colors.red.withOpacity(0.1),
                  Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton("إتمام", Colors.black, Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    String title,
    String date,
    String emoji,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.1)
            : const Color(0xFFE5F1FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "الموعد: $date",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_outline, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCompletedHistory(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "تاريخ مكتمل",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Icon(Icons.history, size: 20, color: Colors.green),
            ],
          ),
          const Divider(height: 30),
          _historyRow("استبدال فلتر الهواء", "20 أكتوبر 2023"),
          _historyRow("تغيير الزيت", "05 سبتمبر 2023"),
        ],
      ),
    );
  }

  Widget _buildCustomReminderPromo(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_alert_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 15),
          const Text(
            "تذكيرات مخصصة",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Text(
            "اضبط تذكيرات لتجديد التأمين أو غسيل السيارة",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "إنشاء تذكير جديد",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicContactCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.1)
            : const Color(0xFFE5F1FD),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(child: _iconBtn(Icons.map, "خريطة", Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: _iconBtn(Icons.phone, "اتصال", Colors.green)),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "خبراء العناية",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "★ 4.9",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage('assets/mechanic1.png'),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color txt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _historyRow(String title, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, color: Colors.white, size: 16),
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
