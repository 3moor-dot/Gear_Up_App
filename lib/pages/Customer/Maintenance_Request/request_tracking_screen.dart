import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RequestTrackingScreen extends StatefulWidget {
  final String requestId;

  const RequestTrackingScreen({super.key, required this.requestId});

  @override
  State<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}

class _RequestTrackingScreenState extends State<RequestTrackingScreen> {
  Map<String, dynamic>? requestData;
  bool isLoading = true;
  Timer? _refreshTimer; // لتحديث الحالة تلقائياً كل 10 ثوانٍ

  final List<Map<String, String>> statusOptions = [
    {"value": "Accepted", "label": "تم القبول"},
    {"value": "OnTheWay", "label": "في الطريق"},
    {"value": "Arrived", "label": "وصل"},
    {"value": "InProgress", "label": "قيد الإصلاح"},
    {"value": "Completed", "label": "تم الانتهاء"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    // تحديث تلقائي للحالة كما في الويب
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchRequestDetails(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRequestDetails() async {
    if (widget.requestId.isEmpty) {
      print("Error: Request ID is empty");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.get(
        Uri.parse(
          "https://gearupapp.runasp.net/api/requests/${widget.requestId}",
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            requestData = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        print("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد لون الثيم الأساسي

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "تتبع الطلب",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requestData == null
          ? const Center(child: Text("لا توجد بيانات لهذا الطلب"))
          : RefreshIndicator(
              onRefresh: _fetchRequestDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. شريط تتبع الحالة (Stepper)
                    _buildStatusStepper(requestData?['status'] ?? "Accepted"),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 2. بيانات الميكانيكي
                    if (requestData?['mechanic'] != null) ...[
                      const Text(
                        "الميكانيكي المكلف:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMechanicInfo(requestData!['mechanic']),
                      const SizedBox(height: 20),
                    ],

                    // 3. بيانات الطلب والسيارة
                    const Text(
                      "تفاصيل الخدمة:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: LucideIcons.car,
                      title: "السيارة",
                      value:
                          "${requestData?['car']?['brand'] ?? ''} ${requestData?['car']?['model'] ?? ''}",
                    ),
                    _buildInfoCard(
                      icon: LucideIcons.wrench,
                      title: "نوع الخدمة",
                      value: requestData?['serviceType'] ?? "غير محدد",
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusStepper(String currentStatus) {
    int currentIndex = statusOptions.indexWhere(
      (s) => s['value'] == currentStatus,
    );
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(statusOptions.length, (index) {
            bool isPast = index <= currentIndex;
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index == 0
                              ? Colors.transparent
                              : (index <= currentIndex
                                    ? Colors.green
                                    : Colors.grey[300]),
                        ),
                      ),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isPast
                            ? Colors.green
                            : Colors.grey[300],
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: isPast ? Colors.white : Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index == statusOptions.length - 1
                              ? Colors.transparent
                              : (index < currentIndex
                                    ? Colors.green
                                    : Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusOptions[index]['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isPast ? FontWeight.bold : FontWeight.normal,
                      color: isPast ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMechanicInfo(Map<String, dynamic> mechanic) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(mechanic['profilePhotoUrl'] ?? ''),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${mechanic['firstName']} ${mechanic['lastName']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "تقييم: ${mechanic['averageRating'] ?? '5'} ⭐",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () {}, // يمكنك إضافة مكتبة url_launcher للاتصال
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
