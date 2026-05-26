import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddBookingModal extends StatefulWidget {
  const AddBookingModal({super.key});

  @override
  State<AddBookingModal> createState() => _AddBookingModalState();
}

class _AddBookingModalState extends State<AddBookingModal> {
  final String baseUrl = "https://gearupapp.runasp.net/api";
  List<String> recommendedMechanicIds = [];
  bool isFromChatbot = false;
  // ✅ نفس React (IDs مش names)
  String mechanicId = "";
  String carId = "";
  String mechanicServiceId = "";

  String date = "";
  String slotStart = "";
  String slotEnd = "";

  bool loading = false;

  List<Map<String, String>> mechanics = [];
  List<Map<String, String>> cars = [];
  List<Map<String, dynamic>> services = [];

  bool loadingMechanics = false;
  bool loadingCars = false;
  bool loadingServices = false;

  final primaryColor = const Color(0xFF137FEC);

  @override
  void initState() {
    super.initState();
    loadChatbotBookingData();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> loadChatbotBookingData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCarId = prefs.getString('booking_car_id');

    final mechanicsJson = prefs.getString('recommended_mechanics');

    if (mechanicsJson != null && mechanicsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(mechanicsJson);

        recommendedMechanicIds = List<String>.from(
          decoded.map((e) => e.toString()),
        );

        isFromChatbot = recommendedMechanicIds.isNotEmpty;
      } catch (e) {
        debugPrint("decode error => $e");
      }
    } else {
      isFromChatbot = false;
      recommendedMechanicIds = [];
    }

    await fetchCars();
    await fetchMechanics();

    // ✅ auto select car
    if (savedCarId != null && savedCarId.isNotEmpty) {
      final exists = cars.any((c) => c["id"] == savedCarId);

      if (exists) {
        safeSetState(() {
          carId = savedCarId;
        });
      }
    }

    // ✅ remove after use
    await prefs.remove('booking_car_id');
    await prefs.remove('recommended_mechanics');
  }

  // ================= TOKEN =================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Map<String, String> getHeaders(String? token) {
    if (token == null) return {"Accept": "*/*"};

    return {
      "Authorization": "Bearer $token",
      "Accept": "*/*",
      "Content-Type": "application/json",
    };
  }

  // ================= FETCH =================

  Future<void> fetchMechanics() async {
    try {
      safeSetState(() => loadingMechanics = true);

      final res = await http.get(
        Uri.parse("$baseUrl/mechanics/verified"),
        headers: {"Accept": "*/*"},
      );

      final body = jsonDecode(res.body);

      List data = body["data"] ?? [];

      // ✅ لو جاي من الشات
      if (isFromChatbot && recommendedMechanicIds.isNotEmpty) {
        data = data.where((item) {
          return recommendedMechanicIds.contains(item["id"].toString());
        }).toList();
      }

      final mapped = data
          .where((e) => e["mechanicProfileId"] != null)
          .map<Map<String, String>>(
            (e) => {
              "id": e["id"].toString(),
              "name": "${e["firstName"]} ${e["lastName"]}",
            },
          )
          .toList();

      safeSetState(() {
        mechanics = mapped;
      });

      // ✅ Auto select mechanic
      if (mapped.isNotEmpty && isFromChatbot) {
        mechanicId = mapped.first["id"] ?? "";

        await fetchServices(mechanicId);
      }
    } catch (e) {
      debugPrint("fetchMechanics error => $e");

      safeSetState(() {
        mechanics = [];
      });
    } finally {
      safeSetState(() {
        loadingMechanics = false;
      });
    }
  }

  Future<void> fetchCars() async {
    try {
      final token = await getToken();

      if (token == null) {
        setState(() => cars = []);
        return;
      }

      setState(() => loadingCars = true);

      final res = await http.get(
        Uri.parse("$baseUrl/customers/cars"),
        headers: getHeaders(token),
      );

      final data = jsonDecode(res.body);
      final list = data["cars"] ?? [];

      final mapped = list.map<Map<String, String>>((e) {
        return {
          "id": e["id"].toString(),
          "name": "${e["brand"]} ${e["model"]} - ${e["year"]}",
        };
      }).toList();

      setState(() => cars = mapped);
    } catch (e) {
      cars = [];
    } finally {
      safeSetState(() => loadingCars = false);
    }
  }

  Future<void> fetchServices(String selectedMechanicId) async {
    try {
      if (selectedMechanicId.isEmpty) {
        safeSetState(() {
          services = [];
          mechanicServiceId = "";
        });
        return;
      }

      safeSetState(() {
        loadingServices = true;
        services = [];
        mechanicServiceId = "";
      });

      final token = await getToken();

      final res = await http.get(
        Uri.parse(
          "$baseUrl/specializations/mechanic/$selectedMechanicId/priced-services",
        ),
        headers: getHeaders(token),
      );

      final body = jsonDecode(res.body);

      final data = body is List ? body : body["data"] ?? [];

      final mapped = data.map<Map<String, dynamic>>((e) {
        return {
          "id": e["id"].toString(),
          "name": e["subSpecializationName"],
          "price": double.tryParse(e["price"].toString()) ?? 0,
          "subSpecializationId": e["subSpecializationId"],
        };
      }).toList();

      safeSetState(() {
        services = mapped;
      });
    } catch (e) {
      debugPrint("fetch services error => $e");

      safeSetState(() {
        services = [];
      });
    } finally {
      safeSetState(() {
        loadingServices = false;
      });
    }
  }

  Future<void> submitBooking() async {
    if (mechanicId.isEmpty ||
        carId.isEmpty ||
        mechanicServiceId.isEmpty ||
        date.isEmpty ||
        slotStart.isEmpty ||
        slotEnd.isEmpty) {
      showMsg("من فضلك املي كل البيانات");
      return;
    }

    String toApiTimeFormat(String time) {
      if (time.isEmpty) return "";
      return time.length == 5 ? "$time:00" : time;
    }

    final start = toApiTimeFormat(slotStart);
    final end = toApiTimeFormat(slotEnd);

    if (end.compareTo(start) <= 0) {
      showMsg("وقت النهاية لازم يكون بعد البداية");
      return;
    }

    try {
      final token = await getToken();

      if (token == null) {
        showMsg("انتهت الجلسة");
        return;
      }

      setState(() => loading = true);

      final payload = {
        "mechanicId": mechanicId,
        "carId": carId,
        "mechanicServiceId": mechanicServiceId,
        "date": date,
        "slotStart": start,
        "slotEnd": end,
      };

      final res = await http.post(
        Uri.parse("$baseUrl/bookings"),
        headers: getHeaders(token),
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);

        showMsg("تم إضافة الحجز بنجاح");
      } else {
        final data = jsonDecode(res.body);

        final errors = data["errors"];

        String message =
            errors?["mechanicId"]?[0] ??
            errors?["carId"]?[0] ??
            errors?["mechanicServiceId"]?[0] ??
            errors?["date"]?[0] ??
            errors?["slotStart"]?[0] ??
            errors?["slotEnd"]?[0] ??
            data["error"] ??
            data["title"] ??
            data["message"] ??
            "حدث خطأ أثناء إنشاء الحجز";

        showMsg(message);
      }
    } catch (e) {
      showMsg("خطأ في الاتصال");
    } finally {
      setState(() => loading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1020) : Colors.white;

    final inputBg = isDark
        ? const Color(0xFF137FEC).withOpacity(0.15)
        : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "إضافة حجز جديد",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Mechanics
            buildDropdown(
              "الميكانيكي",
              mechanics,
              mechanicId,
              (val) {
                setState(() {
                  mechanicId = val;
                });
                fetchServices(val);
              },
              inputBg,
              loadingMechanics ? "جاري التحميل..." : "اختر الميكانيكي",
            ),

            // 🔹 Services
            buildDropdown(
              "الخدمة",
              services
                  .map(
                    (e) => {
                      "id": e["id"].toString(),
                      "name": "${e["name"]} - ${e["price"]} EGP",
                    },
                  )
                  .toList(),
              mechanicServiceId,
              (val) {
                setState(() {
                  mechanicServiceId = val;
                });
              },
              inputBg,
              !mechanicId.isNotEmpty
                  ? "اختار ميكانيكي الأول"
                  : loadingServices
                  ? "جاري تحميل الخدمات..."
                  : "اختر الخدمة",
            ),

            // 🔹 Cars
            buildDropdown(
              "السيارة",
              cars,
              carId,
              (val) {
                setState(() {
                  carId = val;
                });
              },
              inputBg,
              loadingCars ? "جاري التحميل..." : "اختر السيارة",
            ),

            const SizedBox(height: 20), const SizedBox(height: 20),

            // 📅 التاريخ
            buildDateField(inputBg),

            // ⏰ وقت البداية
            buildTimeField("وقت البداية", slotStart, (val) {
              safeSetState(() => slotStart = val);
            }, inputBg),

            // ⏰ وقت النهاية
            buildTimeField("وقت النهاية", slotEnd, (val) {
              safeSetState(() => slotEnd = val);
            }, inputBg),
            ElevatedButton(
              onPressed: loading ? null : submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              child: Text(
                loading ? "جاري الإرسال..." : "إرسال الطلب",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateField(Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text("التاريخ"),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                safeSetState(() {
                  date = picked.toIso8601String().split("T")[0];
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                date.isEmpty ? "اختر التاريخ" : date,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeField(
    String label,
    String value,
    Function(String) onPick,
    Color bg,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (picked != null) {
                onPick(
                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}",
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value.isEmpty ? "اختر الوقت" : value,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown(
    String label,
    List<Map<String, String>> items,
    String value,
    Function(String) onChanged,
    Color bg,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text(hint),
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e["id"],
                  child: Text(e["name"]!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
