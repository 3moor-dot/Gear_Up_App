import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String selectedView = "الشهر";

  // التاريخ المرجعي للتقويم (يتغير عند الضغط على الأسهم)
  DateTime _focusedDate = DateTime.now();
  // التاريخ المختار حالياً (لتحديد اليوم باللون الأزرق)
  DateTime _selectedDate = DateTime.now();

  // --- منطق تغيير الشهور ---
  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
  }

  // حساب عدد أيام الشهر المعروض
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // حساب الإزاحة (offset) لليوم الأول في الشهر (مثلاً الشهر يبدأ يوم الثلاثاء)
  int _getFirstDayOffset(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  // بيانات المواعيد التجريبية
  final List<Map<String, dynamic>> todayAppointments = [
    {
      "client": "علي جمال - تويوتا كامري",
      "service": "تغيير الزيت",
      "time": "09:00 AM",
      "status": "confirmed",
    },
    {
      "client": "سارة سميث - فورد F-150",
      "service": "فحص الفرامل",
      "time": "11:00 AM",
      "status": "confirmed",
    },
    {
      "client": "أنس جابر - هوندا سيفيك",
      "service": "فحص المحرك",
      "time": "01:30 PM",
      "status": "pending",
    },
    {
      "client": "ماريا غارسيا - نيسان",
      "service": "غسيل وتلميع",
      "time": "03:00 PM",
      "status": "completed",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);
    final bool isLargeScreen = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF9FAFB),
      endDrawer: !isLargeScreen
          ? const MachineDrawer(currentRoute: '/mechanic/schedule')
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (isLargeScreen)
              const SizedBox(
                width: 280,
                child: MachineDrawer(currentRoute: '/mechanic/schedule'),
              ),
            Expanded(
              child: Column(
                children: [
                  const MachineHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildViewSelector(isDark, primaryColor),
                        const SizedBox(height: 20),
                        _buildCalendarSection(isDark, primaryColor),
                        const SizedBox(height: 24),
                        _buildSectionTitle("مواعيد اليوم المختارة", isDark),
                        const SizedBox(height: 12),
                        _buildAppointmentsList(isDark, primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- قسم التقويم الديناميكي ---
  Widget _buildCalendarSection(bool isDark, Color primaryColor) {
    // تنسيق التاريخ باللغة العربية
    String monthLabel = DateFormat.yMMMM('ar').format(_focusedDate);
    int daysInMonth = _getDaysInMonth(_focusedDate);
    int offset = _getFirstDayOffset(_focusedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  _calendarNavBtn(Icons.chevron_right, isDark, _nextMonth),
                  const SizedBox(width: 8),
                  _calendarNavBtn(Icons.chevron_left, isDark, _prevMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["ح", "ن", "ث", "ر", "خ", "ج", "س"]
                .map(
                  (d) => Text(
                    d,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
              if (index < offset)
                return const SizedBox.shrink(); // المربعات الفارغة قبل بداية الشهر

              int day = index - offset + 1;
              bool isSelected =
                  day == _selectedDate.day &&
                  _focusedDate.month == _selectedDate.month &&
                  _focusedDate.year == _selectedDate.year;

              return InkWell(
                onTap: () => setState(
                  () => _selectedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month,
                    day,
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark ? Colors.white10 : Colors.grey[50]!,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[300] : Colors.black87),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- زر التنقل (تمت إضافة onTap) ---
  Widget _calendarNavBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // --- شريط اختيار العرض ---
  Widget _buildViewSelector(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ["يوم", "أسبوع", "الشهر"].map((view) {
          bool isActive = selectedView == view;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedView = view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    view,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[700]),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- قائمة المواعيد وبطاقة الموعد ---
  Widget _buildAppointmentsList(bool isDark, Color primaryColor) {
    return Column(
      children: todayAppointments
          .map((app) => _appointmentCard(app, isDark, primaryColor))
          .toList(),
    );
  }

  Widget _appointmentCard(
    Map<String, dynamic> app,
    bool isDark,
    Color primaryColor,
  ) {
    Color statusColor;
    String statusText;

    switch (app['status']) {
      case "confirmed":
        statusColor = Colors.green;
        statusText = "مؤكد";
        break;
      case "pending":
        statusColor = Colors.blue;
        statusText = "قيد الانتظار";
        break;
      case "completed":
        statusColor = Colors.orange;
        statusText = "مكتمل";
        break;
      default:
        statusColor = Colors.grey;
        statusText = "";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app['client'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app['service'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                app['time'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
