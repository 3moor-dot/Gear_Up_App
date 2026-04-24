import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  List<dynamic> historyData = [];
  bool loading = true;

  int currentPage = 1;
  final int itemsPerPage = 10;

  // --- Maps زي React ---
  final Map<String, String> statusMap = {
    "Submitted": "تم الإرسال",
    "Dispatching": "جاري التوزيع",
    "Accepted": "تم القبول",
    "OnTheWay": "في الطريق",
    "Arrived": "وصل",
    "InProgress": "قيد التنفيذ",
    "Completed": "مكتمل",
    "Cancelled": "ملغي",
  };

  final Map<String, Color> statusColorMap = {
    "Submitted": Colors.grey,
    "Dispatching": Colors.blue,
    "Accepted": Colors.blueAccent,
    "OnTheWay": Colors.purple,
    "Arrived": Colors.cyan,
    "InProgress": Colors.orange,
    "Completed": Colors.green,
    "Cancelled": Colors.red,
  };

  final List<String> allowedStatuses = [
    "Accepted",
    "OnTheWay",
    "Arrived",
    "InProgress",
    "Completed",
  ];

  final Map<String, String> serviceTypeMap = {
    "Diagnosis": "تشخيص",
    "Tires": "إطارات",
    "BodyRepair": "إصلاح هيكل",
    "OilChange": "تغيير زيت",
  };

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");

      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/requests/history"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = json.decode(res.body);

      setState(() {
        historyData = data["requests"] ?? [];
        currentPage = 1;
      });
    } catch (e) {
      print(e);
      setState(() => historyData = []);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = historyData
        .where((e) => allowedStatuses.contains(e["status"]))
        .toList();

    final indexOfLast = currentPage * itemsPerPage;
    final indexOfFirst = indexOfLast - itemsPerPage;

    final currentItems = filtered.sublist(
      indexOfFirst,
      indexOfLast > filtered.length ? filtered.length : indexOfLast,
    );

    final totalPages = (filtered.length / itemsPerPage).ceil() == 0
        ? 1
        : (filtered.length / itemsPerPage).ceil();

    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: '/customer/servicehistory'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // TITLE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "عرض طلبات الصيانة",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "متابعة جميع طلبات الصيانة الخاصة بسيارتك",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // LIST
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : currentItems.isEmpty
                          ? const Center(child: Text("لا يوجد بيانات"))
                          : ListView.builder(
                              itemCount: currentItems.length,
                              itemBuilder: (context, index) {
                                final row = currentItems[index];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/customer/maintenance_request/request_tracking/${row["requestId"]}",
                                    );
                                  },
                                  child: _buildCard(row, isDark),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 10),

                    // PAGINATION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentPage = (currentPage - 1).clamp(
                                1,
                                totalPages,
                              );
                            });
                          },
                          child: const Text("السابق"),
                        ),
                        const SizedBox(width: 10),
                        Text("$currentPage / $totalPages"),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentPage = (currentPage + 1).clamp(
                                1,
                                totalPages,
                              );
                            });
                          },
                          child: const Text("التالي"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(dynamic row, bool isDark) {
    final status = row["status"];
    final color = statusColorMap[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 المشكلة
          _rowItem("المشكلة", row["issueDescription"] ?? ""),

          const SizedBox(height: 6),

          // 📅 التاريخ
          _rowItem(
            "التاريخ",
            row["createdAt"] != null
                ? DateTime.parse(
                    row["createdAt"],
                  ).toLocal().toString().split(" ")[0]
                : "-",
          ),

          const SizedBox(height: 6),

          // 🚗 السيارة
          _rowItem(
            "السيارة",
            "${row["car"]?["brand"] ?? ""} ${row["car"]?["model"] ?? ""}",
          ),

          const SizedBox(height: 6),

          // 🔧 الخدمة
          _rowItem("الخدمة", serviceTypeMap[row["serviceType"]] ?? "—"),

          const SizedBox(height: 10),

          // 🟢 الحالة + 👨‍🔧 الميكانيكي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الميكانيكي
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        row["assignedMechanic"]?["profilePhotoUrl"] != null
                        ? NetworkImage(
                            row["assignedMechanic"]["profilePhotoUrl"],
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${row["assignedMechanic"]?["firstName"] ?? ""} ${row["assignedMechanic"]?["lastName"] ?? ""}",
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),

              // الحالة
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusMap[status] ?? "—",
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
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
}
