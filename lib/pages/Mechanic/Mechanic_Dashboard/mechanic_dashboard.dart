// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';

class MachineDashboard extends StatefulWidget {
  const MachineDashboard({super.key});

  @override
  State<MachineDashboard> createState() => _MachineDashboardState();
}

class _MachineDashboardState extends State<MachineDashboard> {
  // ================= DATA =================

  List pendingBookings = [];
  List todayAppointments = [];
  List reviews = [];

  dynamic averageRating = "--";

  bool loadingRequests = true;
  bool loadingToday = true;
  bool loadingReviews = true;
  bool loadingRating = true;

  String? actionLoading;

  // ================= TOKEN =================

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Future<String?> getMechanicId() async {
    final token = await getToken();

    if (token == null) return null;

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split(".")[1]))),
      );

      return payload["sub"] ??
          payload["id"] ??
          payload["userId"] ??
          payload["mechanicId"];
    } catch (e) {
      print(e);
      return null;
    }
  }

  // ================= FETCH =================

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
        pendingBookings =
            data.where((b) => b["status"] == "Pending").toList();
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

  Future<void> fetchAverageRating() async {
    try {
      final token = await getToken();
      final mechanicId = await getMechanicId();

      setState(() => loadingRating = true);

      final res = await http.get(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanics/mechanic/$mechanicId/average-rating",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      dynamic ratingValue = "0";

      if (data is num) {
        ratingValue = data.toString();
      } else if (data is Map) {
        ratingValue =
            data["avgRating"] ??
            data["averageRating"] ??
            data["rating"] ??
            "0";
      }

      setState(() {
        averageRating = ratingValue.toString();
      });
    } catch (e) {
      print(e);

      setState(() {
        averageRating = "0";
      });
    } finally {
      setState(() => loadingRating = false);
    }
  }

  Future<void> fetchLatestReviews() async {
    try {
      final token = await getToken();
      final mechanicId = await getMechanicId();

      setState(() => loadingReviews = true);

      final res = await http.get(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanics/mechanic/$mechanicId/latest?count=5",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      final mapped =
          (data["reviews"] as List).map((r) {
            return {
              "id": r["id"],
              "clientName": r["userName"],
              "rating": r["rating"],
              "comment": r["comment"],
              "date": r["createdAt"],
            };
          }).toList();

      setState(() {
        reviews = mapped;
      });
    } catch (e) {
      print(e);

      setState(() {
        reviews = [];
      });
    } finally {
      setState(() => loadingReviews = false);
    }
  }

  // ================= ACTIONS =================

  Future<void> acceptBooking(String id) async {
    final token = await getToken();

    setState(() => actionLoading = id);

    try {
      await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/bookings/$id/accept"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      await Future.wait([
        fetchPending(),
        fetchToday(),
      ]);
    } catch (e) {
      print(e);
    } finally {
      setState(() => actionLoading = null);
    }
  }

  Future<void> rejectBooking(String id) async {
    final token = await getToken();

    setState(() => actionLoading = id);

    try {
      await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/bookings/$id/reject"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      await fetchPending();
    } catch (e) {
      print(e);
    } finally {
      setState(() => actionLoading = null);
    }
  }

  // ================= INIT =================

  @override
  void initState() {
    super.initState();

    fetchPending();
    fetchToday();
    fetchAverageRating();
    fetchLatestReviews();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
      endDrawer: const SizedBox(
        width: 260,
        child: MachineDrawer(
          currentRoute: "/mechanic/dashboard",
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (width > 1024)
              const SizedBox(
                width: 260,
                child: MachineDrawer(
                  currentRoute: "/mechanic/dashboard",
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
                        // ================= HEADER =================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "لوحة التحكم",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black,
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
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ================= STATS =================

                        _buildStats(isDark),

                        const SizedBox(height: 24),

                        // ================= BOOKINGS =================

                        _buildBookings(isDark, width),

                        const SizedBox(height: 24),

                        // ================= APPOINTMENTS + REVIEWS =================

                        width > 900
                            ? Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildAppointments(isDark),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: _buildReviews(isDark),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                _buildAppointments(isDark),

                                const SizedBox(height: 20),

                                _buildReviews(isDark),
                              ],
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

  // ================= STATS =================

  Widget _buildStats(bool isDark) {
    final stats = [
      {
        "title": "طلبات الحجز الجديدة",
        "value":
            loadingRequests
                ? "..."
                : pendingBookings.length.toString(),
        "change": "طلبات قيد الانتظار",
      },
      {
        "title": "مواعيد اليوم",
        "value":
            loadingToday
                ? "..."
                : todayAppointments.length.toString(),
        "change": "موعد مجدول",
      },
      {
        "title": "متوسط التقييم",
        "value":
            loadingRating ? "..." : averageRating.toString(),
        "change": "هذا الشهر",
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 700 ? 1 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2,
              ),
          itemBuilder: (_, i) {
            final stat = stats[i];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                    isDark
                        ? const LinearGradient(
                          colors: [
                            Color(0xFF1A2332),
                            Color(0xFF0D1629),
                          ],
                        )
                        : null,
                color: !isDark ? Colors.white : null,
                borderRadius: BorderRadius.circular(22),
                boxShadow:
                    !isDark
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : [],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    stat["title"]!.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? Colors.grey[400]
                              : Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    stat["value"]!.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    stat["change"]!.toString(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= BOOKINGS =================

  Widget _buildBookings(bool isDark, double width) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF0D1629)
                : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow:
            !isDark
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
                : [],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark
                          ? Colors.white10
                          : Colors.grey.shade200,
                ),
              ),
            ),
            child: const Text(
              "طلبات الحجز الجديدة",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (loadingRequests)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (pendingBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                "لا توجد طلبات جديدة",
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            )
          else if (width > 700)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 30,
                columns: const [
                  DataColumn(label: Text("عميل")),
                  DataColumn(label: Text("العربة")),
                  DataColumn(label: Text("الخدمة")),
                  DataColumn(label: Text("الوقت")),
                  DataColumn(label: Text("الإجراءات")),
                ],
                rows:
                    pendingBookings.map((b) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              b["customerName"],
                            ),
                          ),

                          DataCell(
                            Text(
                              b["carInfo"],
                            ),
                          ),

                          DataCell(
                            Text(
                              b["subSpecializationName"],
                            ),
                          ),

                          DataCell(
                            Text(
                              "${b["slotStart"].substring(0, 5)}",
                            ),
                          ),

                          DataCell(
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed:
                                      actionLoading ==
                                              b["id"]
                                          ? null
                                          : () => acceptBooking(
                                            b["id"],
                                          ),
                                  style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green,
                                        shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    30,
                                                  ),
                                            ),
                                      ),
                                  child: Text(
                                    actionLoading ==
                                            b["id"]
                                        ? "..."
                                        : "موافقة",
                                  ),
                                ),

                                const SizedBox(width: 8),

                                ElevatedButton(
                                  onPressed:
                                      actionLoading ==
                                              b["id"]
                                          ? null
                                          : () => rejectBooking(
                                            b["id"],
                                          ),
                                  style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.red,
                                        shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    30,
                                                  ),
                                            ),
                                      ),
                                  child: const Text("رفض"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children:
                    pendingBookings.map((b) {
                      return Container(
                        margin:
                            const EdgeInsets.only(
                              bottom: 12,
                            ),
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(
                                    0xFF131C2F,
                                  )
                                  : const Color(
                                    0xFFF8FAFC,
                                  ),
                          borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        b["customerName"],
                                        style:
                                            const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                      ),

                                      const SizedBox(
                                        height: 4,
                                      ),

                                      Text(
                                        "${b["carInfo"]} • ${b["subSpecializationName"]}",
                                        style: TextStyle(
                                          color:
                                              Colors
                                                  .grey[500],
                                          fontSize:
                                              12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  b["slotStart"]
                                      .substring(
                                        0,
                                        5,
                                      ),
                                  style:
                                      const TextStyle(
                                        color:
                                            Colors
                                                .blue,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        actionLoading ==
                                                b["id"]
                                            ? null
                                            : () => acceptBooking(
                                              b["id"],
                                            ),
                                    style:
                                        ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors
                                                  .green,
                                          shape:
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      14,
                                                    ),
                                              ),
                                        ),
                                    child: const Text(
                                      "موافقة",
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        actionLoading ==
                                                b["id"]
                                            ? null
                                            : () => rejectBooking(
                                              b["id"],
                                            ),
                                    style:
                                        ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.red,
                                          shape:
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      14,
                                                    ),
                                              ),
                                        ),
                                    child:
                                        const Text("رفض"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ================= APPOINTMENTS =================

  Widget _buildAppointments(bool isDark) {
    return _sectionContainer(
      isDark,
      "مواعيد اليوم",
      loadingToday
          ? const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
          : todayAppointments.isEmpty
          ? _emptyWidget("لا توجد مواعيد اليوم")
          : Column(
            children:
                todayAppointments.map((a) {
                  return _smallCard(
                    isDark,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a["customerName"],
                                style:
                                    const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                              ),
                            ),

                            Text(
                              "${a["slotStart"].substring(0, 5)} - ${a["slotEnd"].substring(0, 5)}",
                              style:
                                  const TextStyle(
                                    color:
                                        Colors.blue,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          a["subSpecializationName"],
                          style: TextStyle(
                            color:
                                Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                          decoration: BoxDecoration(
                            color: Colors.green
                                .withOpacity(.15),
                            borderRadius:
                                BorderRadius.circular(
                                  30,
                                ),
                          ),
                          child: const Text(
                            "مؤكد",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
    );
  }

  // ================= REVIEWS =================

  Widget _buildReviews(bool isDark) {
    return _sectionContainer(
      isDark,
      "المراجعات الأخيرة",
      loadingReviews
          ? const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
          : reviews.isEmpty
          ? _emptyWidget(
            "لا توجد مراجعات حتى الآن",
          )
          : Column(
            children:
                reviews.map((r) {
                  return _smallCard(
                    isDark,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r["clientName"]
                                    .toString(),
                                style:
                                    const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                              ),
                            ),

                            Row(
                              children: List.generate(
                                r["rating"],
                                (i) => const Icon(
                                  Icons.star,
                                  color:
                                      Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          r["comment"]
                              .toString(),
                          style: TextStyle(
                            color:
                                Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          r["date"] != null
                              ? DateTime.parse(
                                r["date"],
                              ).toLocal().toString().split(" ")[0]
                              : "",
                          style: TextStyle(
                            color:
                                Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionContainer(
    bool isDark,
    String title,
    Widget child,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF0D1629)
                : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow:
            !isDark
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
                : [],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark
                          ? Colors.white10
                          : Colors.grey.shade200,
                ),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _smallCard(
    bool isDark, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF131C2F)
                : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark
                  ? Colors.white10
                  : Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }

  Widget _emptyWidget(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }
}