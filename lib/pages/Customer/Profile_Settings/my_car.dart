import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyCarsTab extends StatefulWidget {
  const MyCarsTab({super.key});

  @override
  State<MyCarsTab> createState() => _MyCarsTabState();
}

class _MyCarsTabState extends State<MyCarsTab> {
  // ================= CONFIG =================
  final String baseUrl = "https://gearupapp.runasp.net/api/customers/cars";
  final Color primaryColor = const Color(0xFF137FEC);

  // ================= STATE =================
  List<dynamic> cars = [];
  String? expandedCarId;
  String? editModeId;
  bool loading = false;

  // ================= ADD CONTROLLERS =================
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  File? _newCarImage;

  // ================= EDIT CONTROLLERS =================
  final _editBrandController = TextEditingController();
  final _editModelController = TextEditingController();
  final _editYearController = TextEditingController();
  final _editPlateController = TextEditingController();
  File? _editCarImage;

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  // ================= API =================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  Future<void> fetchCars() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => cars = data['cars']);
      }
    } catch (_) {
      _snack("خطأ في تحميل السيارات", Colors.red);
    }
  }

  Future<void> addCar() async {
    if (_brandController.text.isEmpty || _newCarImage == null) {
      _snack("يرجى إدخال البيانات كاملة", Colors.orange);
      return;
    }

    setState(() => loading = true);

    try {
      final token = await _getToken();

      if (!mounted) return;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/register"),
      );

      request.headers['Authorization'] = "Bearer $token";

      request.fields.addAll({
        "Brand": _brandController.text,
        "Model": _modelController.text,
        "Year": _yearController.text,
        "PlateNumber": _plateController.text,
      });

      request.files.add(
        await http.MultipartFile.fromPath('CarPhoto', _newCarImage!.path),
      );

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _snack("تمت إضافة السيارة بنجاح", Colors.green);
        _clearAddForm();
        fetchCars();
      }
    } catch (_) {
      if (mounted) {
        _snack("فشل إضافة السيارة", Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> updateCar(String id) async {
    setState(() => loading = true);

    try {
      final token = await _getToken();
      final request = http.MultipartRequest('PUT', Uri.parse("$baseUrl/$id"));

      request.headers['Authorization'] = "Bearer $token";
      request.fields.addAll({
        "Brand": _editBrandController.text,
        "Model": _editModelController.text,
        "Year": _editYearController.text,
        "PlateNumber": _editPlateController.text,
      });

      if (_editCarImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('CarPhoto', _editCarImage!.path),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 204) {
        _snack("تم التحديث بنجاح", Colors.green);
        editModeId = null;
        fetchCars();
      }
    } catch (_) {
      _snack("فشل التحديث", Colors.red);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteCar(String id) async {
    try {
      final token = await _getToken();
      await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: {"Authorization": "Bearer $token"},
      );
      cars.removeWhere((c) => c['id'] == id);
      setState(() {});
    } catch (_) {
      _snack("فشل الحذف", Colors.red);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _addCarSection(isDark),
            const SizedBox(height: 30),
            ...cars.map((car) => _carCard(car, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _addCarSection(bool isDark) {
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("إضافة مركبة جديدة"),
          _field("الماركة", _brandController, isDark),
          _field("الموديل", _modelController, isDark),
          _field("سنة الصنع", _yearController, isDark, number: true),
          _field("رقم اللوحة", _plateController, isDark),
          const SizedBox(height: 10),
          _imagePicker(true),
          const SizedBox(height: 15),
          _primaryButton(
            text: "إضافة السيارة",
            loading: loading,
            onTap: addCar,
          ),
        ],
      ),
    );
  }

  Widget _carCard(dynamic car, bool isDark) {
    final expanded = expandedCarId == car['id'];
    final editing = editModeId == car['id'];

    return _card(
      isDark: isDark,
      border: expanded ? primaryColor : null,
      child: Column(
        children: [
          ListTile(
            onTap: () =>
                setState(() => expandedCarId = expanded ? null : car['id']),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                car['carPhotoUrl'],
                width: 60,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              "${car['brand']} ${car['model']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.amber),
                  onPressed: () => _startEdit(car),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteCar(car['id']),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
          if (expanded)
            editing ? _editForm(car, isDark) : _details(car, isDark),
        ],
      ),
    );
  }

  Widget _details(dynamic car, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _info("سنة الصنع", car['year'].toString(), isDark),
          _info("رقم اللوحة", car['plateNumber'], isDark),
        ],
      ),
    );
  }

  Widget _editForm(dynamic car, bool isDark) {
    return Column(
      children: [
        _field("الماركة", _editBrandController, isDark),
        _field("الموديل", _editModelController, isDark),
        _field("سنة الصنع", _editYearController, isDark, number: true),
        _field("رقم اللوحة", _editPlateController, isDark),
        _imagePicker(false),
        const SizedBox(height: 10),
        _primaryButton(
          text: "حفظ التعديلات",
          loading: loading,
          onTap: () => updateCar(car['id']),
        ),
      ],
    );
  }

  // ================= HELPERS =================
  Widget _card({required Widget child, required bool isDark, Color? border}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: border != null ? Border.all(color: border) : null,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.05)),
          ],
        ),
        child: child,
      );

  Widget _field(
    String label,
    TextEditingController c,
    bool isDark, {
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
    ),
  );

  Widget _imagePicker(bool isNew) => GestureDetector(
    onTap: () async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img != null) {
        setState(
          () => isNew
              ? _newCarImage = File(img.path)
              : _editCarImage = File(img.path),
        );
      }
    },
    child: CircleAvatar(
      radius: 35,
      backgroundColor: primaryColor.withOpacity(0.15),
      child: const Icon(Icons.camera_alt, color: Colors.white),
    ),
  );

  Widget _primaryButton({
    required String text,
    required bool loading,
    required VoidCallback onTap,
  }) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );

  Widget _info(String label, String value, bool isDark) => ListTile(
    dense: true,
    title: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white70 : Colors.grey,
      ),
    ),
    subtitle: Text(
      value,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: primaryColor,
        fontSize: 20,
      ),
    ),
  );

  void _startEdit(dynamic car) {
    setState(() {
      editModeId = car['id'];
      expandedCarId = car['id'];
      _editBrandController.text = car['brand'];
      _editModelController.text = car['model'];
      _editYearController.text = car['year'].toString();
      _editPlateController.text = car['plateNumber'];
    });
  }

  void _clearAddForm() {
    _brandController.clear();
    _modelController.clear();
    _yearController.clear();
    _plateController.clear();
    _newCarImage = null;
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
