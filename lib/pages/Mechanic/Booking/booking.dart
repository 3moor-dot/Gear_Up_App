import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String activeTab = "all";
  String searchTerm = "";
  String formatTo12Hour(String time24) {
    try {
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final isPM = hour >= 12;

      hour = hour % 12;
      if (hour == 0) hour = 12;

      final minuteStr = minute.toString().padLeft(2, '0');

      final period = isPM ? "م" : "ص";

      return "${hour.toString().padLeft(2, '0')}:$minuteStr $period";
    } catch (e) {
      return time24;
    }
  }

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allBookings = [];
  Map<String, dynamic>? selectedBooking;
  bool isDetailsLoading = false;
  bool isLoading = true;
  String? errorMessage;

  final String baseUrl = "https://gearupapp.runasp.net/api/bookings";

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      final response = await http.get(
        Uri.parse("$baseUrl/mechanic/my"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          allBookings = List<Map<String, dynamic>>.from(data);

          // تأكيد: لو الـ activeTab الحالية مابقتش موجودة في الداتا الجديدة، نرجعها لـ "all"
          final uniqueStatuses = allBookings
              .map((b) => b['status'].toString())
              .toSet();
          if (activeTab != "all" && !uniqueStatuses.contains(activeTab)) {
            activeTab = "all";
          }
        });
      } else {
        setState(() {
          errorMessage = "فشل تحميل الحجوزات";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      final response = await http.post(
        Uri.parse("$baseUrl/$bookingId/accept"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        await fetchBookings();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      final response = await http.post(
        Uri.parse("$baseUrl/$bookingId/reject"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        await fetchBookings();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> completeBooking(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      final response = await http.post(
        Uri.parse("$baseUrl/$bookingId/complete"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        await fetchBookings();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> showBookingDetails(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.get(
        Uri.parse("$baseUrl/$bookingId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      Navigator.pop(context); // إغلاق الـ Loading Indicator

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          selectedBooking = data;
        });

        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            // استخدام StatefulBuilder يضمن إن الـ UI جوه الـ Bottom Sheet يتحدث لو حصل أكشن
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (_, controller) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1629) : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "تفاصيل الحجز",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: _getStatusBadge(
                                selectedBooking!['status'],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _detailCard(
                              title: "بيانات العميل",
                              isDark: isDark,
                              children: [
                                _detailRow(
                                  "العميل",
                                  selectedBooking!['customerName'],
                                  Icons.person,
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _detailCard(
                              title: "تفاصيل الحجز",
                              isDark: isDark,
                              children: [
                                _detailRow(
                                  "السيارة",
                                  selectedBooking!['carInfo'],
                                  Icons.directions_car,
                                  isDark,
                                ),
                                _detailRow(
                                  "الخدمة",
                                  selectedBooking!['subSpecializationName'] ??
                                      "",
                                  Icons.build,
                                  isDark,
                                ),
                                _detailRow(
                                  "التاريخ",
                                  selectedBooking!['date'],
                                  Icons.calendar_today,
                                  isDark,
                                ),
                                _detailRow(
                                  "الوقت",
                                  "${formatTo12Hour(selectedBooking!['slotStart'])} - ${formatTo12Hour(selectedBooking!['slotEnd'])}",
                                  Icons.access_time,
                                  isDark,
                                ),
                                _detailRow(
                                  "الميكانيكي",
                                  selectedBooking!['mechanicName'] ?? "",
                                  Icons.engineering,
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _detailCard(
                              title: "سجل الوقت",
                              isDark: isDark,
                              children: [
                                _detailRow(
                                  "تاريخ الإنشاء",
                                  selectedBooking!['createdAt'] ?? "",
                                  Icons.history,
                                  isDark,
                                ),
                                _detailRow(
                                  "آخر تحديث",
                                  selectedBooking!['updatedAt'] ?? "—",
                                  Icons.update,
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // أزرار التحكم من داخل الـ Bottom Sheet
                            if (selectedBooking!['status'] == "Pending")
                              Row(
                                children: [
                                  Expanded(
                                    child: _actionBtn(
                                      "موافقة",
                                      Colors.white,
                                      () async {
                                        Navigator.pop(
                                          context,
                                        ); // نقفله فوراً لتجنب التعليق
                                        await acceptBooking(
                                          selectedBooking!['id'],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _actionBtn(
                                      "رفض",
                                      Colors.white,
                                      () async {
                                        Navigator.pop(context);
                                        await rejectBooking(
                                          selectedBooking!['id'],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            if (selectedBooking!['status'] == "Confirmed" ||
                                selectedBooking!['status'] == "Accepted")
                              SizedBox(
                                width: double.infinity,
                                child: _actionBtn(
                                  "إكمال الحجز",
                                  Colors.white,
                                  () async {
                                    Navigator.pop(context);
                                    await completeBooking(
                                      selectedBooking!['id'],
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<Map<String, dynamic>> get filteredBookings {
    return allBookings.where((booking) {
      final matchesTab = activeTab == "all" || booking['status'] == activeTab;

      final matchesSearch =
          booking['customerName'].toString().toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          booking['carInfo'].toString().toLowerCase().contains(
            searchTerm.toLowerCase(),
          ) ||
          (booking['subSpecializationName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchTerm.toLowerCase());

      return matchesTab && matchesSearch;
    }).toList();
  }

  int getCount(String status) {
    if (status == "all") return allBookings.length;
    return allBookings.where((b) => b['status'] == status).length;
  }

  String _getArabicStatus(String status) {
    switch (status) {
      case "Pending":
        return "انتظار";
      case "Confirmed":
      case "Accepted":
        return "موافقة";
      case "Cancelled":
        return "ملغي";
      case "Rejected":
        return "مرفوض";
      case "Completed":
        return "مكتمل";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);
    final bool isLargeScreen = MediaQuery.of(context).size.width > 1024;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text(errorMessage!)));
    }

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
                    const MachineHeader(),
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
            onChanged: (val) {
              setState(() {
                searchTerm = val;
              });
            },
            decoration: InputDecoration(
              hintText: "البحث حسب العميل أو السيارة أو الخدمة...",
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

  Widget _buildTabsBar(bool isDark, Color primaryColor) {
    final uniqueStatuses = allBookings
        .map((b) => b['status'].toString())
        .toSet()
        .toList();

    final tabs = [
      {"id": "all", "label": "الجميع"},
      ...uniqueStatuses.map(
        (status) => {"id": status, "label": _getArabicStatus(status)},
      ),
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
                setState(() {
                  activeTab = tab['id']!;
                });
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

  Widget _buildBookingsList(bool isDark, Color primaryColor) {
    if (filteredBookings.isEmpty) {
      return const Center(child: Text("لا توجد حجوزات"));
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
                    booking['customerName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    booking['carInfo'],
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
          _buildInfoRow(
            Icons.settings,
            "الخدمة:",
            booking['subSpecializationName'] ?? '',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today,
            "الموعد:",
            "${booking['date']} | ${formatTo12Hour(booking['slotStart'])} - ${formatTo12Hour(booking['slotEnd'])}",
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

  Widget _detailCard({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking, Color primaryColor) {
    if (booking['status'] == "Pending") {
      return Row(
        children: [
          Expanded(
            child: _actionBtn("موافقة", Colors.white, () {
              acceptBooking(booking['id']);
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn("رفض", Colors.white, () {
              rejectBooking(booking['id']);
            }),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.visibility, primaryColor, () {
            showBookingDetails(booking['id']);
          }),
        ],
      );
    }

    if (booking['status'] == "Confirmed" || booking['status'] == "Accepted") {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _actionBtn("إكمال الحجز", Colors.blue, () {
              completeBooking(booking['id']);
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _actionBtn("عرض التفاصيل", primaryColor, () {
              showBookingDetails(booking['id']);
            }),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: _actionBtn("عرض التفاصيل", primaryColor, () {
        showBookingDetails(booking['id']);
      }),
    );
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
      case "Pending":
        color = Colors.orange;
        label = "انتظار";
        break;
      case "Confirmed":
      case "Accepted":
        color = Colors.green;
        label = "موافقة";
        break;
      case "Cancelled":
        color = Colors.red;
        label = "ملغي";
        break;
      case "Rejected":
        color = Colors.red;
        label = "مرفوض";
        break;
      case "Completed":
        color = Colors.blue;
        label = "مكتمل";
        break;
      default:
        color = Colors.grey;
        label = status;
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
