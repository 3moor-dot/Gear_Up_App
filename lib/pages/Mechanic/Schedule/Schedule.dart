import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String selectedView = "month";

  DateTime _focusedDate = DateTime.now();
  int? selectedDay = DateTime.now().day;

  bool loadingSchedule = false;
  bool actionLoading = false;

  final String baseUrl = "https://gearupapp.runasp.net/api/bookings";

  List<Map<String, dynamic>> scheduleBookings = [];

  Map<String, dynamic>? selectedBooking;

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  // ================= FETCH =================

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> fetchSchedule() async {
    try {
      setState(() {
        loadingSchedule = true;
      });

      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("userToken");

      final from = formatDate(
        DateTime(_focusedDate.year, _focusedDate.month, 1),
      );

      final to = formatDate(
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0),
      );

      final response = await http.get(
        Uri.parse(
          "$baseUrl/mechanic/my/schedule?from=$from&to=$to",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          scheduleBookings = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        loadingSchedule = false;
      });
    }
  }

  // ================= ACTIONS =================

  Future<void> acceptBooking(String bookingId) async {
    try {
      setState(() {
        actionLoading = true;
      });

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
        await fetchSchedule();

        setState(() {
          selectedBooking?['status'] = "Accepted";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        actionLoading = false;
      });
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      setState(() {
        actionLoading = true;
      });

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
        Navigator.pop(context);

        await fetchSchedule();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        actionLoading = false;
      });
    }
  }

  Future<void> completeBooking(String bookingId) async {
    try {
      setState(() {
        actionLoading = true;
      });

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
        await fetchSchedule();

        setState(() {
          selectedBooking?['status'] = "Completed";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        actionLoading = false;
      });
    }
  }

  // ================= HELPERS =================

  String formatTime(String time) {
    return time.substring(0, 5);
  }

  String getStatusText(String status) {
    switch (status) {
      case "Accepted":
        return "مقبول";

      case "Confirmed":
        return "مؤكد";

      case "Pending":
        return "في انتظار";

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

  Color getStatusColor(String status) {
    switch (status) {
      case "Accepted":
      case "Confirmed":
        return Colors.green;

      case "Pending":
        return Colors.orange;

      case "Cancelled":
      case "Rejected":
        return Colors.red;

      case "Completed":
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstDayOffset(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + 1,
      );
    });

    fetchSchedule();
  }

  void _prevMonth() {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month - 1,
      );
    });

    fetchSchedule();
  }

  // ================= FILTER =================

  List<Map<String, dynamic>> get displayedAppointments {
    if (selectedView == "day") {
      return scheduleBookings.where((b) {
        final d = DateTime.parse(b['date']);

        return d.day == selectedDay &&
            d.month == _focusedDate.month &&
            d.year == _focusedDate.year;
      }).toList()
        ..sort((a, b) => a['slotStart'].compareTo(b['slotStart']));
    }

    if (selectedView == "week") {
      final targetDate = DateTime(
        _focusedDate.year,
        _focusedDate.month,
        selectedDay ?? DateTime.now().day,
      );

      final startOfWeek = targetDate.subtract(
        Duration(days: targetDate.weekday % 7),
      );

      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      return scheduleBookings.where((b) {
        final d = DateTime.parse(b['date']);

        return d.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            ) &&
            d.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    }

    return scheduleBookings;
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = const Color(0xFF137FEC);

    final bool isLargeScreen =
        MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF9FAFB),
      endDrawer: !isLargeScreen
          ? const MachineDrawer(
              currentRoute: '/mechanic/schedule',
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (isLargeScreen)
              const SizedBox(
                width: 280,
                child: MachineDrawer(
                  currentRoute: '/mechanic/schedule',
                ),
              ),

            Expanded(
              child: Column(
                children: [
                  const MachineHeader(),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildViewSelector(
                          isDark,
                          primaryColor,
                        ),

                        const SizedBox(height: 20),

                        _buildCalendarSection(
                          isDark,
                          primaryColor,
                        ),

                        const SizedBox(height: 24),

                        _buildAppointmentsList(
                          isDark,
                          primaryColor,
                        ),
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

  // ================= VIEW SELECTOR =================

  Widget _buildViewSelector(
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          {"id": "day", "label": "اليوم"},
          {"id": "week", "label": "الأسبوع"},
          {"id": "month", "label": "الشهر"},
        ].map((view) {
          bool isActive = selectedView == view['id'];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedView = view['id']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    view['label']!,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? Colors.grey[400]
                              : Colors.grey[700]),
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

  // ================= CALENDAR =================

  Widget _buildCalendarSection(
    bool isDark,
    Color primaryColor,
  ) {
    String monthLabel =
        DateFormat.yMMMM('ar').format(_focusedDate);

    int daysInMonth = _getDaysInMonth(_focusedDate);

    int offset = _getFirstDayOffset(_focusedDate);

    final daysWithBookings = scheduleBookings
        .map(
          (b) => DateTime.parse(b['date']).day,
        )
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1629)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),

              Row(
                children: [
                  _calendarNavBtn(
                    Icons.chevron_right,
                    isDark,
                    _nextMonth,
                  ),

                  const SizedBox(width: 8),

                  _calendarNavBtn(
                    Icons.chevron_left,
                    isDark,
                    _prevMonth,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              "ح",
              "ن",
              "ث",
              "ر",
              "خ",
              "ج",
              "س",
            ]
                .map(
                  (d) => Text(
                    d,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 10),

          if (loadingSchedule)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: daysInMonth + offset,
              itemBuilder: (context, index) {
                if (index < offset) {
                  return const SizedBox.shrink();
                }

                int day = index - offset + 1;

                bool isSelected = day == selectedDay;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            "$day",
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey[300]
                                      : Colors.black87),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (daysWithBookings.contains(day) &&
                            !isSelected)
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration:
                                    BoxDecoration(
                                  color: primaryColor,
                                  borderRadius:
                                      BorderRadius.circular(
                                    100,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _calendarNavBtn(
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
    );
  }

  // ================= APPOINTMENTS =================

  Widget _buildAppointmentsList(
    bool isDark,
    Color primaryColor,
  ) {
    if (loadingSchedule) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (displayedAppointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text("لا توجد مواعيد"),
        ),
      );
    }

    return Column(
      children: displayedAppointments.map((app) {
        return _appointmentCard(
          app,
          isDark,
          primaryColor,
        );
      }).toList(),
    );
  }

  Widget _appointmentCard(
    Map<String, dynamic> app,
    bool isDark,
    Color primaryColor,
  ) {
    final statusColor = getStatusColor(app['status']);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return _buildBottomSheet(
              app,
              isDark,
              primaryColor,
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0D1629)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    primaryColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: primaryColor,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    app['customerName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    app['carInfo'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    app['subSpecializationName'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      formatTime(app['slotStart']),
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Text("-"),
                    ),

                    Text(
                      formatTime(app['slotEnd']),
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor
                        .withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    getStatusText(app['status']),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= BOTTOM SHEET =================

  Widget _buildBottomSheet(
    Map<String, dynamic> booking,
    bool isDark,
    Color primaryColor,
  ) {
    final statusColor =
        getStatusColor(booking['status']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1629)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius:
                    BorderRadius.circular(100),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color:
                    statusColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                getStatusText(booking['status']),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 25),

            _detailTile(
              "العميل",
              booking['customerName'],
            ),

            _detailTile(
              "السيارة",
              booking['carInfo'],
            ),

            _detailTile(
              "الخدمة",
              booking['subSpecializationName'],
            ),

            _detailTile(
              "التاريخ",
              booking['date'],
            ),

            _detailTile(
              "الوقت",
              "${formatTime(booking['slotStart'])} - ${formatTime(booking['slotEnd'])}",
            ),

            _detailTile(
              "الميكانيكي",
              booking['mechanicName'] ?? "",
            ),

            const SizedBox(height: 25),

            if (booking['status'] == "Pending")
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: actionLoading
                          ? null
                          : () async {
                              await acceptBooking(
                                booking['id'],
                              );

                              Navigator.pop(
                                context,
                              );
                            },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green,
                      ),
                      child: const Text(
                        "موافقة",
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: actionLoading
                          ? null
                          : () async {
                              await rejectBooking(
                                booking['id'],
                              );
                            },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red,
                      ),
                      child: const Text("رفض"),
                    ),
                  ),
                ],
              ),

            if (booking['status'] == "Accepted" ||
                booking['status'] ==
                    "Confirmed")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: actionLoading
                      ? null
                      : () async {
                          await completeBooking(
                            booking['id'],
                          );

                          Navigator.pop(
                            context,
                          );
                        },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,
                  ),
                  child: const Text(
                    "إكمال الحجز",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            "$title : ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}