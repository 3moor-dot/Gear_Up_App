import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:gear_up_app/pages/Mechanic/Booking/booking_details.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String activeTab = "all";
  String searchTerm = "";
  final TextEditingController _searchController = TextEditingController();

  // البيانات التجريبية
  final List<Map<String, dynamic>> allBookings = [
    {
      "id": 1,
      "client": "Alice Martin",
      "car": "Toyota Camry",
      "service": "Oil Change",
      "date": "Oct 26, 2:00 PM",
      "status": "new",
    },
    {
      "id": 2,
      "client": "John Doe",
      "car": "Honda Accord",
      "service": "Brake Check",
      "date": "Oct 27, 10:00 AM",
      "status": "new",
    },
    {
      "id": 4,
      "client": "Sami Ahmed",
      "car": "Ford F-150",
      "service": "Engine Tune-up",
      "date": "Oct 28, 4:00 PM",
      "status": "pending",
    },
    {
      "id": 5,
      "client": "Sarah Wilson",
      "car": "Tesla Model 3",
      "service": "Battery Check",
      "date": "Oct 29, 11:00 AM",
      "status": "confirmed",
    },
  ];

  List<Map<String, dynamic>> get filteredBookings {
    return allBookings.where((booking) {
      final matchesTab = activeTab == "all" || booking['status'] == activeTab;
      final matchesSearch =
          booking['client'].toLowerCase().contains(searchTerm.toLowerCase()) ||
          booking['car'].toLowerCase().contains(searchTerm.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();
  }

  int getCount(String status) {
    if (status == "all") return allBookings.length;
    return allBookings.where((b) => b['status'] == status).length;
  }

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
          ? const MachineDrawer(currentRoute: '/mechanic/booking')
          : null,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              if (isLargeScreen)
                const SizedBox(
                  width: 280,
                  child: MachineDrawer(currentRoute: '/mechanics/bookings'),
                ),
              Expanded(
                child: Column(
                  children: [
                    const MachineHeader(), // الهيدر الذي يحتوي على التنبيهات والتبديل
                    _buildTopSection(isDark),
                    _buildTabsBar(isDark, primaryColor),
                    Expanded(child: _buildBookingsList(isDark, primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الهيدر والبحث ---
  Widget _buildTopSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "الحجوزات",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => searchTerm = val),
            decoration: InputDecoration(
              hintText: "البحث حسب العميل أو السيارة...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF0D1629) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- شريط التبويبات (Tabs) ---
  Widget _buildTabsBar(bool isDark, Color primaryColor) {
    final tabs = [
      {"id": "all", "label": "الجميع"},
      {"id": "new", "label": "جديد"},
      {"id": "pending", "label": "قيد الانتظار"},
      {"id": "confirmed", "label": "موافقة"},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final bool isActive = activeTab == tab['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text("${tab['label']} (${getCount(tab['id']!)})"),
              selected: isActive,
              onSelected: (selected) {
                setState(() => activeTab = tab['id']!);
              },
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: isDark ? const Color(0xFF0D1629) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isActive
                    ? primaryColor
                    : (isDark ? Colors.white10 : Colors.grey[200]!),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- قائمة الكروت (Mobile View) ---
  Widget _buildBookingsList(bool isDark, Color primaryColor) {
    if (filteredBookings.isEmpty) {
      return const Center(child: Text("لا توجد حجوزات مطابقة"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _buildBookingCard(booking, isDark, primaryColor);
      },
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['client'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    booking['car'],
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              _getStatusBadge(booking['status']),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.settings, "الخدمة:", booking['service'], isDark),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today,
            "الموعد:",
            booking['date'],
            isDark,
          ),
          const SizedBox(height: 16),
          _buildActionButtons(booking, primaryColor),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking, Color primaryColor) {
    if (booking['status'] == "new") {
      return Row(
        children: [
          Expanded(
            child: _actionBtn("موافقة", Colors.green, () {
              // منطق الموافقة هنا
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn("رفض", Colors.red, () {
              // منطق الرفض هنا
            }),
          ),
          const SizedBox(width: 8),
          // التعديل هنا: العين الآن تفتح صفحة التفاصيل
          _iconBtn(Icons.visibility, primaryColor, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookingDetailsPage(bookingId: booking['id']),
              ),
            );
          }),
        ],
      );
    } else {
      // تم إصلاح مشكلة اللون والـ Background هنا
      return SizedBox(
        width: double.infinity,
        child: _actionBtn("عرض التفاصيل", primaryColor, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingDetailsPage(bookingId: booking['id']),
            ),
          );
        }),
      );
    }
  }
  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case "new":
        color = Colors.blue;
        label = "جديد";
        break;
      case "pending":
        color = Colors.orange;
        label = "انتظار";
        break;
      case "confirmed":
        color = Colors.green;
        label = "موافقة";
        break;
      default:
        color = Colors.grey;
        label = "غير معروف";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
