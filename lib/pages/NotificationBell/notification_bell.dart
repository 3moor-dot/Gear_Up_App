import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../components/Customer/customer_sidebar.dart';
import '../../components/Customer/customer_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  List cars = [];

  HubConnection? connection;

  bool isLoading = true;

  String token = "";
  String getStorageKey() {
    if (token.isEmpty) return "guest_notifications";
    return "notifications_${token.substring(token.length - 10)}";
  }

  Future<void> loadLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(getStorageKey());

    if (saved != null) {
      notifications = List<Map<String, dynamic>>.from(jsonDecode(saved));
    }
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(getStorageKey(), jsonEncode(notifications));
  }

  Future<void> fetchCars() async {
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/customers/cars"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      setState(() {
        cars = data["cars"] ?? [];
      });
    } catch (e) {
      debugPrint("فشل جلب العربيات $e");
    }
  }

  String getCarName(String carId) {
    final car = cars.firstWhere(
      (c) => c["id"].toString() == carId,
      orElse: () => null,
    );

    if (car == null) return "جاري تحميل بيانات السيارة...";

    return "${car["brand"]} ${car["model"]} ${car["year"]}";
  }

  Future<void> connectSignalR() async {
    connection = HubConnectionBuilder()
        .withUrl(
          "https://gearupapp.runasp.net/hubs/notifications",
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .build();

    connection!.on("ReceiveReminderNotification", (data) {
      final reminder = data![0] as Map<String, dynamic>;

      bool exists = notifications.any(
        (n) => n["reminderId"] == reminder["reminderId"],
      );

      if (exists) return;

      final newNotification = {
        "title": reminder["title"] ?? "تنبيه صيانة",
        "message": reminder["message"] ?? "لديك تنبيه جديد",
        "reminderId": reminder["reminderId"],
        "carId": reminder["carId"],
        "time": TimeOfDay.now().format(context),
      };

      setState(() {
        notifications.insert(0, newNotification);
      });

      saveNotifications();
    });

    await connection!.start();
  }

  void removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });

    saveNotifications();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("userToken") ?? "";

    await loadLocalNotifications();

    if (token.isNotEmpty) {
      await fetchCars();
      await connectSignalR();
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    connection?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: '/customer/notifications'),

      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "التنبيهات (${notifications.length})",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: notifications.isEmpty
                          ? const Center(child: Text("لا توجد تنبيهات"))
                          : ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, i) {
                                final n = notifications[i];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),

                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),

                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFEFF6FF),

                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.blue.shade100,
                                    ),
                                  ),

                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.notifications,
                                        color: Colors.blue,
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n["title"] ?? "",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.blue,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            if (n["carId"] != null)
                                              Text(
                                                "🚗 ${getCarName(n["carId"].toString())}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),

                                            const SizedBox(height: 4),

                                            if (n["message"] != null)
                                              Text(
                                                n["message"],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),

                                            const SizedBox(height: 6),

                                            Text(
                                              n["time"],
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => removeNotification(i),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
}
