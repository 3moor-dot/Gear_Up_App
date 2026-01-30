import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Bookings/add_booking_modal.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Bookings/cancel_booking_modal.dart';

class MaintenanceBookingsPage extends StatefulWidget {
  const MaintenanceBookingsPage({super.key});

  @override
  State<MaintenanceBookingsPage> createState() =>
      _MaintenanceBookingsPageState();
}

class _MaintenanceBookingsPageState extends State<MaintenanceBookingsPage> {
  // بيانات تجريبية للحجوزات
  final List<Map<String, dynamic>> _bookings = [
    {
      'mechanic': 'علي جمال',
      'service': 'تغيير زيت',
      'date': '15/12/2025',
      'time': '10:30 AM',
      'status': 'مكتمل',
      'color': Colors.green,
    },
    {
      'mechanic': 'علي جمال',
      'service': 'تغيير زيت',
      'date': '15/12/2025',
      'time': '10:30 AM',
      'status': 'قيد الانتظار',
      'color': Colors.orange,
      'hasActions': true,
    },
    {
      'mechanic': 'علي جمال',
      'service': 'تغيير زيت',
      'date': '15/12/2025',
      'time': '10:30 AM',
      'status': 'ملغي',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      // الدرور يفتح من اليمين بشكل طبيعي لأننا حددنا اللغة عربية في main.dart
      endDrawer: const CustomDrawer(currentRoute: '/bookings'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. العنوان وزر الحجز الجديد
                  _buildPageHeader(primaryColor),

                  const SizedBox(height: 25),

                  // 2. شريط الفلترة الذكي
                  _buildFilterSection(isDark),

                  const SizedBox(height: 25),

                  // 3. قائمة الحجوزات
                  ..._bookings.map(
                    (booking) =>
                        _buildBookingCard(booking, isDark, primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- مكونات الصفحة ---

  Widget _buildPageHeader(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "حجوزات الصيانة",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "تتبع أعمال الصيانة والتكاليف",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddBookingModal(),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "حجز جديد",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.1)
            : const Color(0xFF0F1323),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterDropdown("كل الحالات", isDark)),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterDropdown("كل الوقت", isDark)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    bool isDark,
    Color primaryColor,
  ) {
    Color statusColor = booking['color'];
    bool hasActions = booking['hasActions'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.05)
            : const Color(0xFFE5F1FD),
        borderRadius: BorderRadius.circular(20),
        border: Border(right: BorderSide(color: statusColor, width: 6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoRow(booking['mechanic'], "الميكانيكي:", isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        booking['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoRow(booking['time'], "التوقيت:", isDark),
                    _buildInfoRow(booking['service'], "الخدمة:", isDark),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildInfoRow(booking['date'], "التاريخ:", isDark),
                  ],
                ),
              ],
            ),
          ),
          if (hasActions) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      "تغيير الموعد",
                      Colors.blueGrey,
                      () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionBtn("إلغاء الحجز", Colors.red, () {
                      showDialog(
                        context: context,
                        builder: (context) => const CancelBookingDialog(),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String value, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF137FEC),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActionBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
