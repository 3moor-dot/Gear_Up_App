// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Components بتاعتك
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';

class MachineDashboard extends StatefulWidget {
  const MachineDashboard({super.key});

  @override
  State<MachineDashboard> createState() => _MachineDashboardState();
}

class _MachineDashboardState extends State<MachineDashboard> {
  List pendingBookings = [];
  List todayAppointments = [];

  bool loadingRequests = true;
  bool loadingToday = true;

  String? actionLoading;

  // ===== Reviews ثابتة =====
  final reviews = [
    {
      "client": "مالك جونسون",
      "rating": 5,
      "comment": "خدمة ممتازة جداً وسريعة!",
      "time": "منذ ساعة",
    },
    {
      "client": "سارة أحمد",
      "rating": 5,
      "comment": "تعامل محترم جداً",
      "time": "منذ ساعتين",
    },
  ];

  // ===== API =====
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Future<void> fetchPending() async {
    try {
      final token = await getToken();
      setState(() => loadingRequests = true);

      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/bookings/mechanic/my"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      setState(() {
        pendingBookings = data.where((b) => b["status"] == "Pending").toList();
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => loadingRequests = false);
    }
  }

  Future<void> fetchToday() async {
    try {
      final token = await getToken();
      setState(() => loadingToday = true);

      final res = await http.get(
        Uri.parse(
          "https://gearupapp.runasp.net/api/bookings/mechanic/my/today",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      data.sort((a, b) => a["slotStart"].compareTo(b["slotStart"]));

      setState(() {
        todayAppointments = data;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => loadingToday = false);
    }
  }

  Future<void> acceptBooking(String id) async {
    final token = await getToken();
    setState(() => actionLoading = id);

    await http.post(
      Uri.parse("https://gearupapp.runasp.net/api/bookings/$id/accept"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    await Future.wait([fetchPending(), fetchToday()]);
    setState(() => actionLoading = null);
  }

  Future<void> rejectBooking(String id) async {
    final token = await getToken();
    setState(() => actionLoading = id);

    await http.post(
      Uri.parse("https://gearupapp.runasp.net/api/bookings/$id/reject"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    await fetchPending();
    setState(() => actionLoading = null);
  }

  @override
  void initState() {
    super.initState();
    fetchPending();
    fetchToday();
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.grey[100],
      body: SafeArea(
        child: Row(
          children: [
            if (width > 1024)
              const SizedBox(
                width: 260,
                child: MachineDrawer(currentRoute: "/mechanic/dashboard"),
              ),

            Expanded(
              child: Column(
                children: [
                  const MachineHeader(),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "لوحة التحكم",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "تابع طلباتك ومواعيدك بسهولة",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildStats(isDark),
                        const SizedBox(height: 20),
                        _buildBookings(isDark, width),
                        const SizedBox(height: 20),
                        _buildAppointments(isDark),
                        const SizedBox(height: 20),
                        _buildReviews(isDark),
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

  // ===== Stats =====
  Widget _buildStats(bool isDark) {
    final stats = [
      {
        "title": "طلبات الحجز",
        "value": loadingRequests ? "..." : pendingBookings.length.toString(),
        "icon": Icons.assignment,
      },
      {
        "title": "مواعيد اليوم",
        "value": loadingToday ? "..." : todayAppointments.length.toString(),
        "icon": Icons.access_time,
      },
      {"title": "التقييم", "value": "4.8", "icon": Icons.star},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (_, i) {
            final s = stats[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0d1629) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(s["icon"] as IconData, color: Colors.blue),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s["title"]! as String),
                      Text(
                        s["value"]! as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== Bookings =====
  Widget _buildBookings(bool isDark, double width) {
    if (loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingBookings.isEmpty) {
      return _emptyCard("لا توجد طلبات جديدة", isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("طلبات الحجز الجديدة"),
        const SizedBox(height: 10),

        ...pendingBookings.map((b) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131c2f) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b["customerName"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${b["carInfo"]} • ${b["subSpecializationName"]}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      b["slotStart"].substring(0, 5),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: actionLoading == b["id"]
                            ? null
                            : () => acceptBooking(b["id"]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          actionLoading == b["id"] ? "..." : "موافقة",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: actionLoading == b["id"]
                            ? null
                            : () => rejectBooking(b["id"]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("رفض"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ===== Appointments =====
  Widget _buildAppointments(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("مواعيد اليوم"),
        const SizedBox(height: 10),

        if (loadingToday)
          const Center(child: CircularProgressIndicator())
        else if (todayAppointments.isEmpty)
          _emptyCard("لا توجد مواعيد اليوم", isDark)
        else
          ...todayAppointments.map((a) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131c2f) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a["customerName"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "${a["slotStart"].substring(0, 5)} - ${a["slotEnd"].substring(0, 5)}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    a["subSpecializationName"],
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  /// Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "مؤكد",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ===== Reviews =====
  Widget _buildReviews(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("المراجعات"),
        const SizedBox(height: 10),

        ...reviews.map((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131c2f) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r["client"].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        r["rating"] as int,
                        (i) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r["comment"].toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  r["time"].toString(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131c2f) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey[500])),
    );
  }
}
