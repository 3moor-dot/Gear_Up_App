import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../components/Customer/customer_sidebar.dart';
import '../../components/Customer/customer_header.dart';
import 'notification_events.dart';

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
  String? role;
  bool isShaking = false;
  late final StreamSubscription _eventSub;
  void triggerShake() {
    setState(() => isShaking = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => isShaking = false);
      }
    });
  }

  final Map<String, String> statusMap = {
    "Accepted": "تم القبول",
    "OnTheWay": "في الطريق",
    "Arrived": "وصل الميكانيكي",
    "InProgress": "جاري الإصلاح",
    "Completed": "تم الانتهاء",
    "Cancelled": "تم الإلغاء",
  };

  String getStorageKey() {
    if (token.isEmpty) return "guest_notifications";
    return "notifications_${token.substring(token.length - 10)}";
  }

  Future<void> loadLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(getStorageKey());
    if (saved != null) {
      List<dynamic> decoded = jsonDecode(saved);
      notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(getStorageKey(), jsonEncode(notifications));

    // 👇 زي storage event
    NotificationEvents.emit("storageUpdated");
  }

  void removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    saveNotifications();
  }

  // ======================= APIs =======================

  Future<void> fetchCars() async {
    if (token.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/customers/cars"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          cars = data["cars"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("فشل جلب السيارات $e");
    }
  }

  Future<void> completeReminder(dynamic reminderId, int index) async {
    try {
      final res = await http.post(
        Uri.parse(
          "https://gearupapp.runasp.net/api/Reminder/${reminderId.toString()}/complete",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تسجيل الإتمام بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
        removeNotification(index);
        NotificationEvents.emit("reminderCompleted");
      } else {
        throw Exception("Status code: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error completeReminder: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("فشل تسجيل الإتمام"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> snoozeReminder(
    dynamic reminderId,
    int snoozeType,
    int index,
  ) async {
    try {
      final res = await http.post(
        Uri.parse(
          "https://gearupapp.runasp.net/api/Reminder/${reminderId.toString()}/snooze",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"snoozeType": snoozeType}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تأجيل التذكير"),
            backgroundColor: Colors.green,
          ),
        );
        removeNotification(index);
        NotificationEvents.emit("reminderSnoozed");
      } else {
        throw Exception("Status code: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error snoozeReminder: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("فشل تأجيل التذكير"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleAccept(String requestId, int index) async {
    try {
      final res = await http.post(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanic/requests/$requestId/accept",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم قبول الطلب ✅"),
            backgroundColor: Colors.green,
          ),
        );
        removeNotification(index);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("فشل قبول الطلب ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleReject(String requestId, int index) async {
    try {
      final res = await http.post(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanic/requests/$requestId/reject",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم رفض الطلب ❌"),
            backgroundColor: Colors.green,
          ),
        );
        removeNotification(index);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("فشل رفض الطلب ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ======================= SignalR =======================

  Future<void> connectSignalR() async {
    connection!.onclose(
      ({error}) => print("SignalR Connection Closed: $error"),
    );
    connection = HubConnectionBuilder()
        .withUrl(
          "https://gearupapp.runasp.net/hubs/notifications",
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            // 👇 أضف هذا السطر لإجبار التطبيق على استخدام WebSockets
            transport: HttpTransportType.WebSockets,
          ),
        )
        .build();

    connection!.serverTimeoutInMilliseconds = 60000;
    connection!.keepAliveIntervalInMilliseconds = 15000;

    // 1. استلام تنبيهات الصيانة
    connection!.on("ReceiveReminderNotification", (args) {
      final data = args![0] as Map<String, dynamic>;

      setState(() {
        notifications.removeWhere((n) => n["reminderId"] == data["reminderId"]);

        notifications.insert(0, {
          "title": data["title"] ?? "تنبيه صيانة",
          "message": data["message"] ?? "لديك تنبيه جديد",
          "reminderId": data["reminderId"],
          "carId": data["carId"],
          "time": TimeOfDay.now().format(context),
          "isRequest": false,
        });
      });
      triggerShake(); // 👈 ضيف دي
      saveNotifications();
    });

    // 2. استلام طلبات الصيانة (للميكانيكي)
    connection!.on("ReceiveServiceRequest", (args) {
      final data = args![0] as Map<String, dynamic>;
      final car = data["car"] as Map<String, dynamic>?;

      String carName = (car != null && car["brand"] != null)
          ? "${car["brand"]} ${car["model"]} ${car["year"]}"
          : "سيارة غير محددة";

      setState(() {
        notifications.insert(0, {
          "title": "طلب صيانة جديد 🛠️",
          "isRequest": true,
          "requestId": data["requestId"] ?? data["serviceRequestId"],
          "scheduledDateTime": data["scheduledDateTime"],
          "carName": carName,
          "plateNumber": car?["plateNumber"] ?? "غير متوفر",
          "requestDetail": data["requestType"] == "Emergency"
              ? "طلب طارئ 🚨"
              : data["requestType"] == "Scheduled"
              ? "طلب مجدول 📅"
              : "طلب صيانة",
          "description": data["issueDescription"],
          "location": data["location"],
          "time": TimeOfDay.now().format(context),
        });
      });
      triggerShake(); // 👈 ضيف دي
      saveNotifications();
    });

    // 3. الميكانيكي وافق (للعميل)
    connection!.on("MechanicAccepted", (args) async {
      final data = args![0] as Map<String, dynamic>;
      String mechanicName = "ميكانيكي";

      try {
        final res = await http.get(
          Uri.parse(
            "https://gearupapp.runasp.net/api/requests/${data["serviceRequestId"]}/accepted-mechanics",
          ),
          headers: {"Authorization": "Bearer $token"},
        );
        if (res.statusCode == 200) {
          final resData = jsonDecode(res.body);
          final mechanics = resData["mechanics"] as List;
          final mechanic = mechanics.firstWhere(
            (m) => m["mechanicUserId"] == data["mechanicUserId"],
            orElse: () => null,
          );
          if (mechanic != null) {
            mechanicName = "${mechanic["firstName"]} ${mechanic["lastName"]}";
          }
        }
      } catch (e) {
        debugPrint("Error fetching mechanic: $e");
      }

      setState(() {
        notifications.insert(0, {
          "title": "تم قبول طلبك 🎉",
          "message": "تم قبول الطلب بواسطة الميكانيكي $mechanicName 🛠️",
          "mechanicName": mechanicName,
          "requestId": data["requestId"] ?? data["serviceRequestId"],
          "isRequest": true,
          "time": TimeOfDay.now().format(context),
        });
      });
      triggerShake(); // 👈 ضيف دي
      saveNotifications();
      NotificationEvents.emit("mechanicAccepted");
    });

    // 4. تم اختيارك كميكانيكي (للميكانيكي)
    connection!.on("YouAreSelected", (args) {
      final data = args![0] as Map<String, dynamic>;
      setState(() {
        notifications.insert(0, {
          "title": "تم اختيارك 🎉",
          "message": "تم اختيارك من قبل العميل.",
          "requestId": data["serviceRequestId"],
          "hasTracking": true,
          "isRequest": true,
          "isSelected": true,
          "time": TimeOfDay.now().format(context),
        });
      });
      triggerShake(); // 👈 ضيف دي
      saveNotifications();
    });

    // 5. تغير حالة الطلب
    connection!.on("RequestStatusChanged", (args) async {
      final data = args![0] as Map<String, dynamic>;
      final id = data["requestId"] ?? data["serviceRequestId"];
      if (id == null) return;

      String issue = "طلب صيانة";
      String mechanicName = "الميكانيكي";

      try {
        final res = await http.get(
          Uri.parse("https://gearupapp.runasp.net/api/requests/$id/status"),
          headers: {"Authorization": "Bearer $token"},
        );
        if (res.statusCode == 200) {
          final fullData = jsonDecode(res.body);
          issue = fullData["issueDescription"] ?? issue;
          if (fullData["mechanic"] != null) {
            mechanicName =
                "${fullData["mechanic"]["firstName"]} ${fullData["mechanic"]["lastName"]}";
          }
        }
      } catch (e) {
        debugPrint("Status fetch error: $e");
      }

      setState(() {
        notifications.insert(0, {
          "title": "🔄 تم تحديث حالة الطلب",
          "description":
              "المشكلة: $issue\nتم تحديث الحالة إلى: ${statusMap[data["newStatus"]] ?? data["newStatus"]}\nبواسطة الميكانيكي: $mechanicName",
          "requestId": id,
          "status": data["newStatus"],
          "isRequest": true,
          "hasTracking": true,
          "time": TimeOfDay.now().format(context),
        });
      });
      triggerShake(); // 👈 ضيف دي
      saveNotifications();
    });

    try {
      await connection!.start();
      debugPrint("SignalR Connected ✅");
    } catch (e) {
      debugPrint("SignalR Connection Error ❌ $e");
    }
  }

  // ======================= Init & Helpers =======================

  void decodeJWTAndSetRole(String tokenStr) {
    try {
      final parts = tokenStr.split(".");
      if (parts.length == 3) {
        final payloadStr = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final payload = jsonDecode(payloadStr);
        role =
            payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      }
    } catch (e) {
      debugPrint("JWT parse error: $e");
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("userToken") ?? "";

    if (token.isNotEmpty) {
      decodeJWTAndSetRole(token);
    }

    await loadLocalNotifications();
    triggerShake();
    setState(() {});

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

    // 👇 ده الجديد
    _eventSub = NotificationEvents.stream.listen((event) async {
      if (event == "reminderCompleted" ||
          event == "reminderSnoozed" ||
          event == "mechanicAccepted" ||
          event == "storageUpdated") {
        await loadLocalNotifications();
        setState(() {});
        triggerShake();
      }
    });

    init();
  }

  @override
  void dispose() {
    _eventSub.cancel(); // 👈 مهم جدا
    connection?.stop();
    super.dispose();
  }

  String getCarName(String? carId) {
    if (carId == null) return "";
    final car = cars.firstWhere(
      (c) => c["id"].toString() == carId.toString(),
      orElse: () => null,
    );
    if (car == null) return "جاري تحميل بيانات السيارة...";
    return "${car["brand"]} ${car["model"]} ${car["year"]}";
  }

  // نافذة التأجيل (بديلة للـ Dropdown في React)
  void showSnoozeDialog(dynamic reminderId, int index) {
    final snoozeOptions = [
      {"label": "دقيقتين", "value": 5},
      {"label": "ساعة واحدة", "value": 0},
      {"label": "3 ساعات", "value": 1},
      {"label": "يوم واحد", "value": 2},
      {"label": "3 أيام", "value": 3},
      {"label": "أسبوع", "value": 4},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "اختر مدة التأجيل",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...snoozeOptions.map(
                (opt) => ListTile(
                  title: Text(
                    opt["label"] as String,
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    snoozeReminder(reminderId, opt["value"] as int, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : notifications.isEmpty
                          ? const Center(
                              child: Text(
                                "لا توجد تنبيهات",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, i) {
                                final n = notifications[i];
                                final bool isRequest = n["isRequest"] ?? false;

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
                                      AnimatedRotation(
                                        turns: isShaking ? 0.05 : 0,
                                        duration: const Duration(
                                          milliseconds: 100,
                                        ),
                                        child: const Icon(
                                          Icons.notifications,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // العنوان
                                            Text(
                                              n["title"] ?? "",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // اسم السيارة
                                            if (n["carName"] != null ||
                                                n["carId"] != null)
                                              Text(
                                                "🚗 ${n["carName"] ?? getCarName(n["carId"]?.toString())} ${n["plateNumber"] != null ? '(${n["plateNumber"]})' : ''}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                            if (!isRequest &&
                                                n["reminderId"] != null)
                                              const Text(
                                                "تنبيه صيانة",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                            const SizedBox(height: 4),

                                            // تفاصيل الطلب (لو كان طلب)
                                            if (isRequest) ...[
                                              if (n["requestDetail"] != null)
                                                Text(
                                                  n["requestDetail"],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              if (n["scheduledDateTime"] !=
                                                  null)
                                                Text(
                                                  n["scheduledDateTime"]
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              if (n["description"] != null)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 8,
                                                    bottom: 8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withOpacity(0.1),
                                                    border: const Border(
                                                      right: BorderSide(
                                                        color: Colors.blue,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    n["description"],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),

                                              // أزرار الميكانيكي (قبول / رفض / تتبع)
                                              if (role?.toLowerCase() ==
                                                  "mechanic") ...[
                                                if (n["hasTracking"] == true)
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.blue,
                                                          ),
                                                      onPressed: () {
                                                        // Navigator.pushNamed(context, '/tracking_route', arguments: n["requestId"]);
                                                      },
                                                      child: const Text(
                                                        "تتبع الطلب",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                else if (n["requestId"] != null)
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.green
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                            elevation: 0,
                                                          ),
                                                          onPressed: () =>
                                                              handleAccept(
                                                                n["requestId"]
                                                                    .toString(),
                                                                i,
                                                              ),
                                                          child: const Text(
                                                            "قبول",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                            elevation: 0,
                                                          ),
                                                          onPressed: () =>
                                                              handleReject(
                                                                n["requestId"]
                                                                    .toString(),
                                                                i,
                                                              ),
                                                          child: const Text(
                                                            "رفض",
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ],

                                            // الرسالة العادية (إذا لم يكن طلب ميكانيكي مفصل)
                                            if (n["message"] != null)
                                              Text(
                                                n["message"],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),

                                            // أزرار التذكير (إتمام / تأجيل)
                                            if (!isRequest &&
                                                n["reminderId"] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () =>
                                                            completeReminder(
                                                              n["reminderId"],
                                                              i,
                                                            ),
                                                        child: const Text(
                                                          "إتمام",
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.orange
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () =>
                                                            showSnoozeDialog(
                                                              n["reminderId"],
                                                              i,
                                                            ),
                                                        child: const Text(
                                                          "تأجيل",
                                                          style: TextStyle(
                                                            color:
                                                                Colors.orange,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            const SizedBox(height: 6),
                                            Text(
                                              n["time"] ?? "",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // زر الحذف (X)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => removeNotification(i),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
