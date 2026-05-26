// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ====== IMPORTS بتاعتك ======
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Bookings/add_booking_modal.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Bookings/cancel_booking_modal.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Bookings/reschedule_modal.dart';

// =====================================================
// 🔥 1) Layout زي React (Header + Sidebar ثابت)
// =====================================================
class CustomerLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const CustomerLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: CustomDrawer(currentRoute: currentRoute),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// 🔥 2) الصفحة نفسها (نفس UI بتاعك بالظبط)
// =====================================================
class MaintenanceBookingsPage extends StatefulWidget {
  const MaintenanceBookingsPage({super.key});

  @override
  State<MaintenanceBookingsPage> createState() =>
      _MaintenanceBookingsPageState();
}

class _MaintenanceBookingsPageState extends State<MaintenanceBookingsPage> {
  bool _openedFromChatbot = false;
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String _selectedStatus = "الكل";
  String _selectedTimeFilter = "كل الوقت";
  bool showCancelModal = false;
  String? selectedBookingId;
  final String _apiUrl = "https://gearupapp.runasp.net/api/bookings/my";

  @override
  void initState() {
    super.initState();
    _fetchBookings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOpenBookingModal();
    });
  }

  // ================= API =================
  Future<void> _checkOpenBookingModal() async {
    if (_openedFromChatbot) return;

    final prefs = await SharedPreferences.getInstance();

    final mechanicsJson = prefs.getString('recommended_mechanics');
    final carId = prefs.getString('booking_car_id');

    final hasChatbotData =
        mechanicsJson != null &&
        mechanicsJson.isNotEmpty &&
        carId != null &&
        carId.isNotEmpty;

    if (hasChatbotData && mounted) {
      _openedFromChatbot = true;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AddBookingModal(),
      );
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? "";

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _bookings = data;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load bookings");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
    }
  }

  // ================= FILTER =================
  List<dynamic> get _filteredBookings {
    final statusMap = {
      'Pending': 'قيد الانتظار',
      'Confirmed': 'مؤكد',
      'Accepted': 'مقبول',
      'Cancelled': 'ملغي',
      'Rejected': 'مرفوض',
      'Completed': 'مكتمل',
    };

    final now = DateTime.now();

    return _bookings.where((booking) {
      bool statusMatch =
          _selectedStatus == "الكل" ||
          statusMap[booking['status']] == _selectedStatus;

      DateTime bookingDate = DateTime.parse(booking['date']);

      bool timeMatch = true;

      if (_selectedTimeFilter == "اليوم") {
        timeMatch =
            bookingDate.year == now.year &&
            bookingDate.month == now.month &&
            bookingDate.day == now.day;
      } else if (_selectedTimeFilter == "هذا الأسبوع") {
        final nextWeek = now.add(const Duration(days: 7));
        timeMatch = bookingDate.isAfter(now) && bookingDate.isBefore(nextWeek);
      } else if (_selectedTimeFilter == "هذا الشهر") {
        timeMatch =
            bookingDate.month == now.month && bookingDate.year == now.year;
      }

      return statusMatch && timeMatch;
    }).toList();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Stack(
      children: [
        CustomerLayout(
          currentRoute: '/customer/bookings',
          child: RefreshIndicator(
            onRefresh: _fetchBookings,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPageHeader(primaryColor),
                const SizedBox(height: 25),
                _buildFilterSection(isDark),
                const SizedBox(height: 25),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_filteredBookings.isEmpty)
                  const Center(child: Text("لا توجد حجوزات متاحة"))
                else
                  ..._filteredBookings.map(
                    (booking) =>
                        _buildBookingCard(booking, isDark, primaryColor),
                  ),
              ],
            ),
          ),
        ),

        /// 🔥 المودال هنا
        CancelBookingModal(
          isOpen: showCancelModal,
          bookingId: selectedBookingId,
          onClose: () {
            setState(() {
              showCancelModal = false;
              selectedBookingId = null; // 🔥 مهم
            });
          },
          onSuccess: () async {
            await _fetchBookings(); // 🔥 يعمل refresh زي React
          },
        ),
      ],
    );
  }

  // ================= FILTER UI =================
  Widget _buildFilterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              _selectedStatus,
              ["الكل", "قيد الانتظار", "مقبول", "ملغي", "مكتمل"],
              (val) => setState(() => _selectedStatus = val!),
              isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterDropdown(
              _selectedTimeFilter,
              ["كل الوقت", "اليوم", "هذا الأسبوع", "هذا الشهر"],
              (val) => setState(() => _selectedTimeFilter = val!),
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1323) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF0F1323) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  // ================= CARD =================
  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    bool isDark,
    Color primaryColor,
  ) {
    Color statusColor;
    switch (booking['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFE5F1FD),
        borderRadius: BorderRadius.circular(20),
        border: Border(right: BorderSide(color: statusColor, width: 6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info(
                  booking['mechanicName'] ?? "غير معروف",
                  "الميكانيكي:",
                ), // ✅ الجديد
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _info(
                        formatDisplayDate(booking['date']),
                        "التاريخ:",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _info(
                        booking['slotStart'].substring(0, 5),
                        "التوقيت:",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                _info(booking['subSpecializationName'] ?? "صيانة", "الخدمة:"),
              ],
            ),
          ),

          if (booking['status'] == 'Pending' ||
              booking['status'] == 'Completed')
            _actions(booking),
        ],
      ),
    );
  }

  Widget _actions(Map booking) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (booking['status'] == 'Pending') ...[
                Expanded(
                  child: _btn("تعديل", Colors.blueGrey, () {
                    showDialog(
                      context: context,
                      builder: (_) => RescheduleModal(
                        booking: booking as Map<String, dynamic>,
                        onSuccess: () {
                          _fetchBookings();
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _btn("إلغاء", Colors.red, () {
                    setState(() {
                      showCancelModal = true;
                      selectedBookingId = booking['id'];
                    });
                  }),
                ),
              ],
              if (booking['status'] == 'Completed')
                Expanded(
                  child: _btn("⭐ تقييم", Colors.amber, () {
                    _showRatingDrawer(booking);
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= RATING =================
  void _showRatingDrawer(Map booking) {
    int stars = 0;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                "تقييم الخدمة",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setStateModal(() => stars = i + 1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "تعليق",
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: stars == 0
                    ? null
                    : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم التقييم")),
                        );
                      },
                child: const Text("إرسال"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _info(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF137FEC))),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

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
            Text("تتبع أعمال الصيانة", style: TextStyle(color: Colors.grey)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddBookingModal(),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "حجز جديد",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        ),
      ],
    );
  }
}
