// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';

class MRequestHistory extends StatefulWidget {
  const MRequestHistory({super.key});

  @override
  State<MRequestHistory> createState() => _MRequestHistoryState();
}

class _MRequestHistoryState extends State<MRequestHistory> {
  List requests = [];

  bool loading = true;

  int currentPage = 1;
  final int itemsPerPage = 8;

  // ================= STATUS =================

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

  final Map<String, Color> statusBg = {
    "Submitted": Colors.grey,
    "Dispatching": Colors.blue,
    "Accepted": Colors.indigo,
    "OnTheWay": Colors.purple,
    "Arrived": Colors.cyan,
    "InProgress": Colors.orange,
    "Completed": Colors.green,
    "Cancelled": Colors.red,
  };

  final Map<String, String> serviceTypeMap = {
    "Tires": "إطارات",
    "Battery": "بطارية",
    "Engine": "محرك",
    "Maintenance": "صيانة",
    "OilChange": "تغيير زيت",
    "Electrical": "كهرباء",
    "Diagnosis": "تشخيص",
    "BodyRepair": "إصلاح هيكل",
  };

  // ================= TOKEN =================

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  // ================= FETCH =================

  Future<void> fetchRequests() async {
    try {
      final token = await getToken();

      if (token == null) return;

      setState(() => loading = true);

      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/mechanic/requests"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      setState(() {
        requests = data["requests"] ?? [];
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= INIT =================

  @override
  void initState() {
    super.initState();

    fetchRequests();
  }

  // ================= PAGINATION =================

  List get currentRequests {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;

    return requests.sublist(
      start,
      end > requests.length ? requests.length : end,
    );
  }

  int get totalPages => (requests.length / itemsPerPage).ceil();

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF8FAFC),

      endDrawer: const SizedBox(
        width: 260,
        child: MachineDrawer(currentRoute: "/mechanic/request-history"),
      ),

      body: SafeArea(
        child: Row(
          children: [
            if (width > 1024)
              const SizedBox(
                width: 260,
                child: MachineDrawer(currentRoute: "/mechanic/request-history"),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "طلبات الصيانة",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "عرض طلبات الصيانة والتقييمات",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ================= CONTENT =================
                        if (loading)
                          SizedBox(
                            height: 400,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            ),
                          )
                        else if (currentRequests.isEmpty)
                          _emptyState(isDark)
                        else
                          Column(
                            children: [
                              if (width > 768)
                                _desktopTable(isDark)
                              else
                                _mobileCards(isDark),

                              const SizedBox(height: 24),

                              if (requests.length > itemsPerPage)
                                _pagination(isDark),
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

  // ================= DESKTOP TABLE =================

  Widget _desktopTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: !isDark
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
          // HEADER
          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),

            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "المشكلة",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    "العميل",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    "السيارة",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: Text(
                    "الخدمة",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: Text(
                    "الحالة",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: Text(
                    "التقييم",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: Text(
                    "السعر",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ROWS
          ...currentRequests.map((req) {
            return InkWell(
              onTap: () {
                showRequestDetailsSheet(context, req, isDark);
              },

              child: Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                  ),
                ),

                child: Row(
                  children: [
                    // ISSUE
                    Expanded(
                      flex: 3,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            req["issueDescription"] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            req["createdAt"] != null
                                ? DateTime.parse(
                                    req["createdAt"],
                                  ).toLocal().toString().split(".")[0]
                                : "",

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CUSTOMER
                    Expanded(
                      flex: 2,

                      child: Row(
                        children: [
                          req["customer"]["profilePhotoUrl"] != null
                              ? CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(
                                    req["customer"]["profilePhotoUrl"],
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "${req["customer"]["firstName"]} ${req["customer"]["lastName"]}",

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CAR
                    Expanded(
                      flex: 2,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "${req["car"]["brand"]} ${req["car"]["model"]}",

                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            req["car"]["plateNumber"] ?? "",

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SERVICE
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131C2F)
                              : const Color(0xFFF1F5F9),

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          serviceTypeMap[req["serviceType"]] ?? "—",

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // STATUS
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: (statusBg[req["status"]] ?? Colors.grey)
                              .withOpacity(.15),

                          borderRadius: BorderRadius.circular(30),
                        ),

                        child: Text(
                          statusMap[req["status"]] ?? "—",

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            color: statusBg[req["status"]],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // RATING
                    Expanded(
                      child: req["rating"] != null
                          ? _stars(req["rating"]["stars"].toDouble())
                          : Text(
                              "غير مقيم",

                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                    ),

                    // PRICE
                    Expanded(
                      child: req["price"] != null
                          ? Text(
                              "${req["price"]} ج.م",

                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              "—",

                              style: TextStyle(color: Colors.grey[500]),
                            ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= MOBILE =================

  Widget _mobileCards(bool isDark) {
    return Column(
      children: currentRequests.map((req) {
        return InkWell(
          borderRadius: BorderRadius.circular(22),

          onTap: () {
            showRequestDetailsSheet(context, req, isDark);
          },

          child: Container(
            margin: const EdgeInsets.only(bottom: 14),

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1629) : Colors.white,

              borderRadius: BorderRadius.circular(22),

              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),

              boxShadow: !isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // TOP
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child: Text(
                        req["issueDescription"] ?? "",

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: (statusBg[req["status"]] ?? Colors.grey)
                            .withOpacity(.15),

                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: Text(
                        statusMap[req["status"]] ?? "—",

                        style: TextStyle(
                          color: statusBg[req["status"]],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // BODY
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        "العميل",
                        "${req["customer"]["firstName"]}",
                        Icons.person,
                        isDark,
                      ),
                    ),

                    Expanded(
                      child: _infoItem(
                        "السيارة",
                        "${req["car"]["brand"]} ${req["car"]["model"]}",
                        Icons.directions_car,
                        isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        "الخدمة",
                        serviceTypeMap[req["serviceType"]] ?? "—",
                        Icons.build,
                        isDark,
                      ),
                    ),

                    Expanded(
                      child: _infoItem(
                        "التاريخ",
                        req["createdAt"] != null
                            ? DateTime.parse(
                                req["createdAt"],
                              ).toLocal().toString().split(" ")[0]
                            : "",
                        Icons.access_time,
                        isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // FOOTER
                Container(
                  padding: const EdgeInsets.only(top: 14),

                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "التقييم",

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),

                          const SizedBox(height: 6),

                          req["rating"] != null
                              ? _stars(req["rating"]["stars"].toDouble())
                              : Text(
                                  "—",

                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,

                        children: [
                          Text(
                            "السعر",

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),

                          const SizedBox(height: 6),

                          req["price"] != null
                              ? Text(
                                  "${req["price"]} ج.م",

                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  "—",

                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= PAGINATION =================

  Widget _pagination(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        ElevatedButton(
          onPressed: currentPage == 1
              ? null
              : () {
                  setState(() {
                    currentPage--;
                  });
                },

          child: const Text("السابق"),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),

          child: Text(
            "صفحة $currentPage من $totalPages",

            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),

        ElevatedButton(
          onPressed: currentPage == totalPages
              ? null
              : () {
                  setState(() {
                    currentPage++;
                  });
                },

          child: const Text("التالي"),
        ),
      ],
    );
  }

  // ================= HELPERS =================

  Widget _stars(double stars) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          Icons.star,

          size: 16,

          color: index < stars ? Colors.amber : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _infoItem(String title, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),

              const SizedBox(height: 2),

              Text(
                value,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      height: 420,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            width: 90,
            height: 90,

            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,

              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.directions_car,
              size: 40,
              color: Colors.grey[400],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "لا توجد طلبات حالياً",

            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "لم يتم استلام أي طلبات صيانة حتى الآن",

            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void showRequestDetailsSheet(
    BuildContext context,
    Map<String, dynamic> request,
    bool isDark,
  ) {
    final statusOptions = {
      "Accepted": "تم القبول",
      "OnTheWay": "في الطريق",
      "Arrived": "وصل",
      "InProgress": "قيد الإصلاح",
      "Completed": "تم الانتهاء",
      "Cancelled": "تم الإلغاء",
    };

    final serviceTypeMap = {
      "Diagnosis": "تشخيص",
      "Tires": "إطارات",
      "BodyRepair": "إصلاح هيكل",
      "OilChange": "تغيير زيت",
    };

    final requestTypeMap = {"Emergency": "طارئ", "Scheduled": "مجدول"};

    final serviceModeMap = {
      "MechanicComesToCustomer": "الميكانيكي يذهب للعميل",
      "CustomerGoesToMechanic": "العميل يأتي للميكانيكي",
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0d1629) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              /// Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          const Icon(
                            Icons.car_repair,
                            color: Colors.blue,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "تفاصيل الطلب",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      /// CAR
                      if (request["car"]?["carPhotoUrl"] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            request["car"]["carPhotoUrl"],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 18),

                      _infoCard(
                        isDark,
                        icon: Icons.directions_car,
                        title: "السيارة",
                        value:
                            "${request["car"]?["brand"]} ${request["car"]?["model"]} - ${request["car"]?["year"]}",
                      ),

                      const SizedBox(height: 12),

                      _infoCard(
                        isDark,
                        icon: Icons.confirmation_number,
                        title: "رقم اللوحة",
                        value: request["car"]?["plateNumber"] ?? "--",
                      ),

                      const SizedBox(height: 20),

                      /// CUSTOMER
                      Text(
                        "بيانات العميل",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131c2f)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  request["customer"]?["profilePhotoUrl"] !=
                                      null
                                  ? NetworkImage(
                                      request["customer"]["profilePhotoUrl"],
                                    )
                                  : null,
                              child:
                                  request["customer"]?["profilePhotoUrl"] ==
                                      null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${request["customer"]?["firstName"]} ${request["customer"]?["lastName"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request["customer"]?["phoneNumber"] ?? "--",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ISSUE
                      _sectionTitle("المشكلة", isDark),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131c2f)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          request["issueDescription"] ?? "--",
                          style: TextStyle(
                            height: 1.6,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      if (request["problemPhotoUrl"] != null) ...[
                        const SizedBox(height: 14),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            request["problemPhotoUrl"],
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      /// DETAILS
                      _sectionTitle("تفاصيل الطلب", isDark),

                      const SizedBox(height: 12),

                      _infoCard(
                        isDark,
                        icon: Icons.warning_amber_rounded,
                        title: "نوع الطلب",
                        value: requestTypeMap[request["requestType"]] ?? "--",
                      ),

                      const SizedBox(height: 12),

                      _infoCard(
                        isDark,
                        icon: Icons.settings,
                        title: "طريقة الخدمة",
                        value: serviceModeMap[request["serviceMode"]] ?? "--",
                      ),

                      const SizedBox(height: 12),

                      _infoCard(
                        isDark,
                        icon: Icons.build,
                        title: "الخدمة",
                        value: serviceTypeMap[request["serviceType"]] ?? "--",
                      ),

                      const SizedBox(height: 12),

                      _infoCard(
                        isDark,
                        icon: Icons.check_circle,
                        title: "الحالة",
                        value: statusOptions[request["status"]] ?? "--",
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _infoCard(
    bool isDark, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131c2f) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
