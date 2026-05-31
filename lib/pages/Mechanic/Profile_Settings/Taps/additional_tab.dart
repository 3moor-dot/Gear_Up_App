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
    initData();
  }

  @override
  void dispose() {
    workFromController.dispose();
    workToController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // ================= INITIALIZATION =================
  Future<void> initData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString("userToken") ?? "";

      // جلب التخصصات أولاً لربط الـ IDs بالأسماء كما يحدث في الـ React
      await fetchSpecializations();
      
      // جلب بيانات الميكانيكي الحالية من السيرفر فوراً لتحديث الـ UI
      await fetchMechanicData();
    } catch (e) {
      print("Error in initData: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= API CALLS =================
  Future<void> fetchSpecializations() async {
    try {
      final response = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/Specialization"),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            specializations = jsonDecode(response.body);
          });
        }
      }
    } catch (e) {
      print("Error fetching specializations: $e");
    }
  }

  Future<void> fetchMechanicData() async {
    try {
      final response = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/Mechanic/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            latitude = data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null;
            longitude = data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null;
            mainSpecialty = data['mainSpecializationId']?.toString() ?? "";
            subSpecialty = data['subSpecializationId']?.toString() ?? "";
            fieldVisit = data['fieldVisit'] ?? false;
            isAvailable = data['isAvailable'] ?? false;
            workFrom = data['workingHoursFrom']?.toString().substring(0, 5) ?? "08:00";
            workTo = data['workingHoursTo']?.toString().substring(0, 5) ?? "18:00";
            licenseUrl = data['licenseImage'];

            workFromController.text = workFrom;
            workToController.text = workTo;
          });

          if (latitude != null && longitude != null && mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLng(LatLng(latitude!, longitude!)),
            );
          }
        }
      }
    } catch (e) {
      print("Error fetching mechanic data: $e");
    }
  }

  Future<void> updateMechanicData() async {
    if (!mounted) return;
    setState(() => isSaving = true);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("https://gearupapp.runasp.net/api/Mechanic/update-additional"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
      });

      // إرسال البيانات بنفس الهيكلية الدقيقة لـ React Payload
      request.fields['Latitude'] = latitude?.toString() ?? "";
      request.fields['Longitude'] = longitude?.toString() ?? "";
      request.fields['MainSpecializationId'] = mainSpecialty;
      request.fields['SubSpecializationId'] = subSpecialty;
      request.fields['FieldVisit'] = fieldVisit.toString();
      request.fields['IsAvailable'] = isAvailable.toString();
      request.fields['WorkingHoursFrom'] = workFrom;
      request.fields['WorkingHoursTo'] = workTo;

      if (licenseFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('LicenseImage', licenseFile!.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ التعديلات بنجاح")),
        );
        if (mounted) {
          setState(() {
            isEditing = false;
            licenseFile = null; // تصفير الملف المؤقت لاعتماد الرابط الجديد من السيرفر
          });
        }
        // تحديث البيانات فوراً من السيرفر لمطابقة التحديثات (Refetch)
        await fetchMechanicData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل حفظ البيانات، يرجى المحاولة مرة أخرى")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // ================= HELPER FUNCTIONS =================
  Future<void> getCurrentLocation() async {
    if (!isEditing) return;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });

        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(latitude!, longitude!)),
          );
        }
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> pickLicenseImage() async {
    if (!isEditing || _isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        setState(() {
          licenseFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    if (!isEditing) return;
    
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

    if (picked != null && mounted) {
      final formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
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

  List<dynamic> getSubSpecialties() {
    if (mainSpecialty.isEmpty) return [];
    final main = specializations.firstWhere(
      (s) => s['id'].toString() == mainSpecialty,
      orElse: () => null,
    );
    return main != null ? main['subSpecializations'] ?? [] : [];
  }

  // ================= UI BUILDERS =================
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // شريط التحكم العلوي (تعديل / حفظ) متطابق تماماً مع أزرار React هيدر الكارد
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "البيانات الإضافية",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  isEditing
                      ? ElevatedButton.icon(
                          onPressed: isSaving ? null : updateMechanicData,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 16),
                          label: Text(isSaving ? "جاري الحفظ..." : "حفظ"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => setState(() => isEditing = true),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("تعديل البيانات"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // القسم الأول: الموقع الجغرافي
                    _buildSectionCard(
                      title: "الموقع الجغرافي (الورشة)",
                      dark: dark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (latitude != null && longitude != null)
                                      ? "تم تحديد الموقع: (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})"
                                      : "لم يتم تحديد الموقع بعد",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: dark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (isEditing)
                                TextButton.icon(
                                  onPressed: getCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 16),
                                  label: const Text("موقعي الحالي"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(latitude ?? 26.8206, longitude ?? 30.8025),
                                  zoom: (latitude != null) ? 14.0 : 5.0,
                                ),
                                onMapCreated: (controller) => mapController = controller,
                                markers: (latitude != null && longitude != null)
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('workshop'),
                                          position: LatLng(latitude!, longitude!),
                                        )
                                      }
                                    : {},
                                onTap: isEditing
                                    ? (LatLng pos) {
                                        setState(() {
                                          latitude = pos.latitude;
                                          longitude = pos.longitude;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // القسم الثاني: التخصصات والخدمات
                    _buildSectionCard(
                      title: "التخصص والخدمات",
                      dark: dark,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: mainSpecialty.isEmpty ? null : mainSpecialty,
                            hint: const Text("اختر التخصص الرئيسي"),
                            decoration: InputDecoration(
                              labelText: "التخصص الرئيسي",
                              filled: true,
                              fillColor: dark ? const Color(0xFF0D1629) : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: specializations.map((spec) {
                              return DropdownMenuItem<String>(
                                value: spec['id'].toString(),
                                child: Text(spec['name'] ?? ""),
                              );
                            }).toList(),
                            onChanged: isEditing
                                ? (val) {
                                    setState(() {
                                      mainSpecialty = val ?? "";
                                      subSpecialty = ""; // تصفير الفرعي لمطابقة React تلقائياً عند تغيير الرئيسي
                                    });
                                  }
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: subSpecialty.isEmpty ? null : subSpecialty,
                            hint: const Text("اختر التخصص الفرعي"),
                            decoration: InputDecoration(
                              labelText: "التخصص الفرعي",
                              filled: true,
                              fillColor: dark ? const Color(0xFF0D1629) : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: getSubSpecialties().map((sub) {
                              return DropdownMenuItem<String>(
                                value: sub['id'].toString(),
                                child: Text(sub['name'] ?? ""),
                              );
                            }).toList(),
                            onChanged: isEditing
                                ? (val) {
                                    setState(() => subSpecialty = val ?? "");
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // القسم الثالث: التوافر والعمل الميداني
                    _buildSectionCard(
                      title: "حالة العمل والتوافر",
                      dark: dark,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text("تقديم خدمة الدعم الفني الميداني"),
                            subtitle: const Text("السماح بالذهاب لموقع العميل المتعطل"),
                            value: fieldVisit,
                            activeColor: primaryColor,
                            onChanged: isEditing
                                ? (val) => setState(() => fieldVisit = val)
                                : null,
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text("متاح للعمل الآن"),
                            subtitle: const Text("استقبال طلبات الحجوزات المباشرة الفورية"),
                            value: isAvailable,
                            activeColor: primaryColor,
                            onChanged: isEditing
                                ? (val) => setState(() => isAvailable = val)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // القسم الرابع: ساعات العمل
                    _buildSectionCard(
                      title: "ساعات العمل اليومية",
                      dark: dark,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: workFromController,
                              readOnly: true,
                              onTap: () => _selectTime(context, true),
                              decoration: InputDecoration(
                                labelText: "من الساعة",
                                prefixIcon: const Icon(Icons.access_time),
                                filled: true,
                                fillColor: dark ? const Color(0xFF0D1629) : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: workToController,
                              readOnly: true,
                              onTap: () => _selectTime(context, false),
                              decoration: InputDecoration(
                                labelText: "إلى الساعة",
                                prefixIcon: const Icon(Icons.access_time),
                                filled: true,
                                fillColor: dark ? const Color(0xFF0D1629) : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // القسم الخامس: مستند رخصة المزاولة
                    _buildSectionCard(
                      title: "رخصة مزاولة المهنة الفنية",
                      dark: dark,
                      child: GestureDetector(
                        onTap: pickLicenseImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF0D1629) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                            ),
                          ),
                          child: _buildLicenseContent(dark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseContent(bool dark) {
    if (licenseFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(licenseFile!, fit: BoxFit.cover),
      );
    } else if (licenseUrl != null && licenseUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          licenseUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text("خطأ في تحميل صورة الرخصة"));
          },
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, size: 40, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            isEditing ? "اضغط لرفع صورة رخصة المزاولة" : "لم يتم رفع أي ملف رخصة بعد",
            style: TextStyle(
              fontSize: 12,
              color: dark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required bool dark,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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