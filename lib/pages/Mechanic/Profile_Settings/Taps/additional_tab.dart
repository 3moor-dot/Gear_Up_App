// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdditionalTab extends StatefulWidget {
  const AdditionalTab({super.key});

  @override
  State<AdditionalTab> createState() => _AdditionalTabState();
}

class _AdditionalTabState extends State<AdditionalTab> {
  // ================= STATE =================
  bool isEditing = false;
  bool isSaving = false;
  bool isLoading = true;
  bool _isPickingImage = false;
  String token = "";

  double? latitude;
  double? longitude;

  String mainSpecialty = "";
  String subSpecialty = "";

  bool fieldVisit = false;
  bool isAvailable = false;

  String workFrom = "08:00";
  String workTo = "18:00";

  File? licenseFile;
  String? licenseUrl;

  final workFromController = TextEditingController();
  final workToController = TextEditingController();
  List<dynamic> specializations = [];

  String cacheKey = "mechanic_cache";
  GoogleMapController? mapController;

  final Color primaryColor = const Color(0xFF137FEC);

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    workFromController.dispose();
    workToController.dispose();
    super.dispose();
  }

  // ================= INIT =================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("userToken") ?? "";

    // جلب البيانات من الكاش أولاً لتجربة مستخدم سريعة جداً (Optimistic UI)
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      setState(() {
        latitude = data["latitude"];
        longitude = data["longitude"];
        mainSpecialty = data["mainSpecialty"]?.toString() ?? "";
        subSpecialty = data["subSpecialty"]?.toString() ?? "";
        fieldVisit = data["fieldVisit"] ?? false;
        isAvailable = data["isAvailable"] ?? false;
        workFrom = data["workFrom"] ?? "08:00";
        workTo = data["workTo"] ?? "18:00";
        licenseUrl = data["licenseUrl"];
        workFromController.text = workFrom;
        workToController.text = workTo;
      });
    }

    await Future.wait([fetchProfile(), fetchSpecializations()]);
    setState(() => isLoading = false);
  }

  // ================= FETCH PROFILE =================
  Future<void> fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/mechanics/my/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          latitude = data["latitude"];
          longitude = data["longitude"];
          mainSpecialty = data["primarySpecializationId"]?.toString() ?? "";
          subSpecialty = data["subSpecializationId"]?.toString() ?? "";
          fieldVisit = data["supportsFieldVisit"] ?? false;
          isAvailable = data["isAvailable"] ?? false;
          workFrom = data["workStartTime"] ?? "08:00";
          workTo = data["workEndTime"] ?? "18:00";
          licenseUrl = data["workshopLicenseUrl"];

          workFromController.text = workFrom;
          workToController.text = workTo;
        });

        if (latitude != null && longitude != null && mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(latitude!, longitude!)),
          );
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  // ================= SPECIALIZATIONS =================
  Future<void> fetchSpecializations() async {
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/specializations"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        setState(() {
          specializations = jsonDecode(res.body);
        });
      }
    } catch (e) {
      print("Error fetching specializations: $e");
    }
  }

  // ================= LOCATION =================
  Future<void> getMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
      );
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // ================= PICK IMAGE =================
  // ======= PICK IMAGE =======
Future<void> pickImage() async {
  // الحماية من الضغطات المتعددة لمنع خطأ الـ PlatformException
  if (_isPickingImage) return;

  setState(() {
    _isPickingImage = true;
  });

  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // جودة ممتازة ومناسبة للرفع على السيرفر
    );

    if (pickedFile != null) {
      setState(() {
        // 🔥 التعديل هنا: استخدام المتغير الصحيح الخاص بهذا الملف
        licenseFile = File(pickedFile.path); 
      });
    }
  } catch (e) {
    print("Error picking image: $e");
  } finally {
    setState(() {
      _isPickingImage = false;
    });
  }
}
  // ================= SAVE (React 1:1) =================
  Future<void> saveAll() async {
    setState(() => isSaving = true);

    try {
      // 1 LOCATION
      await http.put(
        Uri.parse("https://gearupapp.runasp.net/api/mechanics/my/location"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"latitude": latitude, "longitude": longitude}),
      );

      // 2 SPECIALIZATION
      await http.put(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanics/my/profile/complete",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "primarySpecializationId": int.tryParse(mainSpecialty),
          "subSpecializationId": int.tryParse(subSpecialty),
        }),
      );

      // 3 FIELD VISIT
      await http.put(
        Uri.parse("https://gearupapp.runasp.net/api/mechanics/my/field-visit"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"supportsFieldVisit": fieldVisit}),
      );

      // 4 WORK HOURS
      await http.put(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanics/my/working-hours",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"workStartTime": workFrom, "workEndTime": workTo}),
      );

      // 5 AVAILABILITY
      await http.put(
        Uri.parse("https://gearupapp.runasp.net/api/mechanics/availability"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(isAvailable),
      );

      // 6 LICENSE UPLOAD
      if (licenseFile != null) {
        final req = http.MultipartRequest(
          "POST",
          Uri.parse("https://gearupapp.runasp.net/api/mechanics/documents"),
        );

        req.headers["Authorization"] = "Bearer $token";
        req.files.add(
          await http.MultipartFile.fromPath("File", licenseFile!.path),
        );

        await req.send();
      }

      // 7 CACHE (React localStorage)
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
        cacheKey,
        jsonEncode({
          "latitude": latitude,
          "longitude": longitude,
          "mainSpecialty": mainSpecialty,
          "subSpecialty": subSpecialty,
          "fieldVisit": fieldVisit,
          "isAvailable": isAvailable,
          "workFrom": workFrom,
          "workTo": workTo,
          "licenseUrl": licenseUrl,
        }),
      );

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم الحفظ بنجاح"),
          backgroundColor: Colors.green,
        ),
      );

      // جلب البيانات من جديد لتحديث أي قيم من السيرفر
      fetchProfile();
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء الحفظ"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= CANCEL =================
  Future<void> cancelEdit() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      final data = jsonDecode(cached);

      setState(() {
        latitude = data["latitude"];
        longitude = data["longitude"];
        mainSpecialty = data["mainSpecialty"]?.toString() ?? "";
        subSpecialty = data["subSpecialty"]?.toString() ?? "";
        fieldVisit = data["fieldVisit"] ?? false;
        isAvailable = data["isAvailable"] ?? false;
        workFrom = data["workFrom"] ?? "08:00";
        workTo = data["workTo"] ?? "18:00";
        licenseUrl = data["licenseUrl"];

        workFromController.text = workFrom;
        workToController.text = workTo;
        licenseFile = null;
      });
    }

    setState(() => isEditing = false);
  }

  // ================= TIME PICKER CONFIG =================
  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final currentStr = isFrom ? workFrom : workTo;
    final parts = currentStr.split(":");
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        if (isFrom) {
          workFrom = formattedTime;
          workFromController.text = formattedTime;
        } else {
          workTo = formattedTime;
          workToController.text = formattedTime;
        }
      });
    }
  }

  // ================= IMAGE WIDGET =================
  Widget buildLicense(bool dark) {
    ImageProvider? imageProvider;

    if (licenseFile != null) {
      imageProvider = FileImage(licenseFile!);
    } else if (licenseUrl != null && licenseUrl!.isNotEmpty) {
      imageProvider = NetworkImage(licenseUrl!);
    }

    if (imageProvider == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 40, color: primaryColor),
            const SizedBox(height: 8),
            Text(
              "اضغط لرفع صورة رخصة الورشة",
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: imageProvider,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // تجهيز قوائم التخصصات
    var mainItem = specializations.firstWhere(
      (element) => element["id"].toString() == mainSpecialty,
      orElse: () => null,
    );
    List<dynamic> subList = mainItem != null
        ? (mainItem["subSpecializations"] ?? [])
        : [];

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B1220) : Colors.grey.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "البيانات الإضافية والمهنية",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            if (isEditing)
                              TextButton(
                                onPressed: isSaving ? null : cancelEdit,
                                child: const Text(
                                  "إلغاء",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      if (isEditing) {
                                        saveAll();
                                      } else {
                                        setState(() => isEditing = true);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEditing
                                    ? Colors.green
                                    : primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      isEditing ? Icons.check : Icons.edit,
                                      size: 14,
                                    ),
                              label: Text(isEditing ? "حفظ" : "تعديل"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ================= SPECIALIZATIONS SECTION =================
                    _buildSectionCard(
                      title: "التخصص والخبرة",
                      dark: dark,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: mainSpecialty.isEmpty ? null : mainSpecialty,
                            hint: const Text("اختر التخصص الرئيسي"),
                            disabledHint: Text(
                              mainItem != null ? mainItem["name"] : "غير محدد",
                            ),
                            items: specializations.map((spec) {
                              return DropdownMenuItem<String>(
                                value: spec["id"].toString(),
                                child: Text(spec["name"] ?? ""),
                              );
                            }).toList(),
                            onChanged: isEditing
                                ? (v) {
                                    setState(() {
                                      mainSpecialty = v ?? "";
                                      subSpecialty =
                                          ""; // تصفير الفرعي لتجنب الكراش
                                    });
                                  }
                                : null,
                            decoration: const InputDecoration(
                              labelText: "التخصص الرئيسي",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: subSpecialty.isEmpty ? null : subSpecialty,
                            hint: const Text("اختر التخصص الفرعي"),
                            disabledHint: Text(
                              subList.firstWhere(
                                    (e) => e["id"].toString() == subSpecialty,
                                    orElse: () => {"name": "غير محدد"},
                                  )["name"] ??
                                  "غير محدد",
                            ),
                            items: subList.map((sub) {
                              return DropdownMenuItem<String>(
                                value: sub["id"].toString(),
                                child: Text(sub["name"] ?? ""),
                              );
                            }).toList(),
                            onChanged: isEditing
                                ? (v) => setState(() => subSpecialty = v ?? "")
                                : null,
                            decoration: const InputDecoration(
                              labelText: "التخصص الفرعي",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ================= WORK HOURS SECTION =================
                    _buildSectionCard(
                      title: "مواعيد العمل اليومية",
                      dark: dark,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: isEditing
                                  ? () => _selectTime(context, true)
                                  : null,
                              child: IgnorePointer(
                                child: TextField(
                                  controller: workFromController,
                                  decoration: const InputDecoration(
                                    labelText: "من",
                                    prefixIcon: Icon(Icons.access_time),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: isEditing
                                  ? () => _selectTime(context, false)
                                  : null,
                              child: IgnorePointer(
                                child: TextField(
                                  controller: workToController,
                                  decoration: const InputDecoration(
                                    labelText: "إلى",
                                    prefixIcon: Icon(Icons.access_time_filled),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ================= STATUS SWITCHES =================
                    _buildSectionCard(
                      title: "الحالة والخيارات المدعومة",
                      dark: dark,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                              "تقديم خدمات ورش متنقلة (زيارة ميدانية)",
                            ),
                            value: fieldVisit,
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: isEditing
                                ? (v) => setState(() => fieldVisit = v)
                                : null,
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text(
                              "متاح لاستقبال الطلبات الفورية الآن",
                            ),
                            value: isAvailable,
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: isEditing
                                ? (v) => setState(() => isAvailable = v)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ================= LOCATION MAP SECTION =================
                    _buildSectionCard(
                      title: "موقع الورشة على الخريطة",
                      dark: dark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            clipBehavior: Clip
                                .antiAlias, // منع الخريطة من الخروج عن الحواف
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  latitude ?? 26.8206,
                                  longitude ?? 30.8025,
                                ),
                                zoom: 14,
                              ),
                              onMapCreated: (c) => mapController = c,
                              onTap: isEditing
                                  ? (pos) {
                                      setState(() {
                                        latitude = pos.latitude;
                                        longitude = pos.longitude;
                                      });
                                    }
                                  : null,
                              markers: (latitude != null)
                                  ? {
                                      Marker(
                                        markerId: const MarkerId(
                                          "workshop_loc",
                                        ),
                                        position: LatLng(latitude!, longitude!),
                                      ),
                                    }
                                  : {},
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: getMyLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                foregroundColor: primaryColor,
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text("تحديد موقعي الحالي"),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ================= LICENSE SECTION =================
                    _buildSectionCard(
                      title: "توثيق ورخصة الورشة",
                      dark: dark,
                      child: GestureDetector(
                        onTap: isEditing ? pickImage : null,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF0F172A)
                                : Colors.grey[100],
                            border: Border.all(
                              color: dark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: buildLicense(dark),
                        ),
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

  // كارد مخصص لتنسيق الأقسام بشكل احترافي ومتناسق
  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required bool dark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF131C2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.grey[900]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
