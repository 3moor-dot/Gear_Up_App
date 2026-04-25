import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final primaryColor = const Color(0xFF137FEC);

  String userName = "";
  bool loading = true;

  List cars = [];
  int selectedCarIndex = 0;

  List reminders = [];
  bool remindersLoading = false;

  List mechanics = [];
  bool mechanicsLoading = false;

  List historyData = [];

  final allowedStatuses = [
    "Accepted",
    "OnTheWay",
    "Arrived",
    "InProgress",
    "Completed",
  ];

  final statusMap = {
    "Submitted": "تم الإرسال",
    "Dispatching": "جاري التوزيع",
    "Accepted": "تم القبول",
    "OnTheWay": "في الطريق",
    "Arrived": "وصل",
    "InProgress": "قيد التنفيذ",
    "Completed": "مكتمل",
    "Cancelled": "ملغي",
  };

  final serviceIconMap = {
    "Diagnosis": "🔍",
    "Tires": "🛞",
    "BodyRepair": "🛠️",
    "OilChange": "🛢️",
  };

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Future<void> fetchAll() async {
    final token = await getToken();
    if (token == null) return;

    await Future.wait([
      fetchProfile(token),
      fetchCars(token),
      fetchMechanics(token),
      fetchHistory(token),
    ]);

    if (cars.isNotEmpty) {
      fetchReminders(token);
    }
  }

  Future<void> fetchProfile(String token) async {
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/users/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      setState(() {
        userName = data["firstName"] ?? "";
      });
    } catch (_) {}
  }

  Future<void> fetchCars(String token) async {
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/requests/cars"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      setState(() {
        cars = data["cars"] ?? [];
      });
    } catch (_) {}
  }

  Future<void> fetchMechanics(String token) async {
    setState(() => mechanicsLoading = true);

    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/mechanics"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      List raw = data["data"] ?? [];

      raw = raw.where((m) {
        if (!m["isActive"] || !m["isAvailable"]) return false;
        return true;
      }).toList();

      setState(() => mechanics = raw);
    } catch (_) {
      setState(() => mechanics = []);
    }

    setState(() => mechanicsLoading = false);
  }

  Future<void> fetchReminders(String token) async {
    if (cars.isEmpty) return;

    final carId = cars[selectedCarIndex]["id"];
    setState(() => remindersLoading = true);

    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder/car/$carId"),
        headers: {"Authorization": "Bearer $token"},
      );

      setState(() {
        reminders = jsonDecode(res.body);
      });
    } catch (_) {
      setState(() => reminders = []);
    }

    setState(() => remindersLoading = false);
  }

  Future<void> fetchHistory(String token) async {
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/requests/history"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      setState(() {
        historyData = data["requests"] ?? [];
      });
    } catch (_) {
      setState(() => historyData = []);
    }

    setState(() => loading = false);
  }

  List get dashboardHistory {
    return historyData
        .where((item) => allowedStatuses.contains(item["status"]))
        .take(3)
        .toList();
  }

  List get upcomingReminders {
    final list = reminders.where((r) => r["status"] == "Active").toList();

    list.sort(
      (a, b) => DateTime.parse(
        a["startDate"],
      ).compareTo(DateTime.parse(b["startDate"])),
    );

    return list.take(3).toList();
  }

  List get topMechanics => mechanics.take(2).toList();

  void switchCar() async {
    if (cars.length > 1) {
      setState(() {
        selectedCarIndex = (selectedCarIndex + 1) % cars.length;
      });

      final token = await getToken();
      if (token != null) fetchReminders(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: "/customer/dashboard"),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// HEADER TEXT
                  Text(
                    "أهلاً بعودتك${userName.isNotEmpty ? " يا $userName" : ""}!",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CAR CARD
                  _carCard(isDark),

                  const SizedBox(height: 20),

                  /// REMINDERS
                  _remindersSection(isDark),

                  const SizedBox(height: 20),

                  /// MECHANICS
                  _mechanicsSection(),

                  const SizedBox(height: 20),

                  /// HISTORY
                  _historySection(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carCard(bool isDark) {
    if (cars.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(child: Text("لا توجد سيارات")),
      );
    }

    final car = cars[selectedCarIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          /// TEXT
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${car["year"] ?? ""} ${car["brand"] ?? ""} ${car["model"] ?? ""}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 5),

                if (car["plateNumber"] != null)
                  Text(
                    "رقم اللوحة: ${car["plateNumber"]}",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),

                const SizedBox(height: 15),

                if (cars.length > 1)
                  ElevatedButton(
                    onPressed: switchCar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      "تبديل (${selectedCarIndex + 1}/${cars.length})",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// IMAGE
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 100,
              child:
                  car["carPhotoUrl"] != null &&
                      car["carPhotoUrl"].toString().isNotEmpty
                  ? Image.network(
                      car["carPhotoUrl"],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.directions_car, size: 50),
                    )
                  : const Icon(Icons.directions_car, size: 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remindersSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "الصيانة القادمة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (remindersLoading)
          const Center(child: CircularProgressIndicator())
        else if (upcomingReminders.isEmpty)
          const Text("لا توجد صيانات")
        else
          ...upcomingReminders.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF93C5FD),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.build, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r["name"] ?? "تذكير",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          r["startDate"],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _mechanicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "الميكانيكيين",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (mechanicsLoading)
          const CircularProgressIndicator()
        else
          ...topMechanics.map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white24,
                    backgroundImage: m["profilePhotoUrl"] != null
                        ? NetworkImage(m["profilePhotoUrl"])
                        : null,
                    child: m["profilePhotoUrl"] == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${m["firstName"]} ${m["lastName"]}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          m["phoneNumber"] ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _historySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "تاريخ الخدمة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (loading)
          const CircularProgressIndicator()
        else if (dashboardHistory.isEmpty)
          const Text("لا يوجد بيانات")
        else
          ...dashboardHistory.map(
            (h) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Text(
                    serviceIconMap[h["serviceType"]] ?? "🔧",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h["issueDescription"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          statusMap[h["status"]] ?? "",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
