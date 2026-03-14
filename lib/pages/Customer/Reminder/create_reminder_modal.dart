import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CreateReminderModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreateReminderModal({super.key, required this.onSuccess});

  @override
  State<CreateReminderModal> createState() => _CreateReminderModalState();

  static void show(BuildContext context, {required VoidCallback onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateReminderModal(onSuccess: onSuccess),
    );
  }
}

class _CreateReminderModalState extends State<CreateReminderModal> {
  bool _isLoading = false;
  List<dynamic> _cars = [];
  Map<String, dynamic>? _selectedCar;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _intervalValueController = TextEditingController(text: "1");

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);
  String _frequencyType = "0"; 
  int _intervalUnit = 0; 

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  // ======= جلب السيارات =======
  Future<void> _fetchCars() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/customers/cars"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cars = data['cars'] ?? [];
          if (_cars.isNotEmpty) _selectedCar = _cars[0];
        });
      }
    } catch (e) {
      debugPrint("Error fetching cars: $e");
    }
  }

  // ======= بوب أب الخطأ المخصص =======
  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تنبيه", textAlign: TextAlign.right, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً")),
        ],
      ),
    );
  }

  // ======= إرسال البيانات (مطابق لـ React) =======
  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _selectedCar == null) {
      _showErrorPopup("يرجى إدخال اسم التذكير واختيار السيارة.");
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    // تنسيق الوقت HH:mm
    final String formattedTime = "${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}";

    // منطق الـ ISO Date مع إضافة 12 ساعة كما في React لتجنب مشاكل الـ Timezone
    String formatToBackend(DateTime date) {
      final fixedDate = date.add(const Duration(hours: 12));
      return fixedDate.toIso8601String();
    }

    final payload = {
      "carId": _selectedCar!['id'], // إرساله كما هو (Guid String)
      "name": _nameController.text,
      "description": _descController.text,
      "startDate": formatToBackend(_startDate),
      "endDate": _endDate != null ? formatToBackend(_endDate!) : null,
      "preferredNotificationTime": formattedTime,
      "frequencyType": _frequencyType == "4" ? 5 : int.parse(_frequencyType),
      "intervalValue": _frequencyType == "4" ? int.parse(_intervalValueController.text) : 0,
      "intervalUnit": _frequencyType == "4" ? _intervalUnit : 0,
    };

    try {
      final res = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        // فك تشفير رسالة الخطأ من السيرفر
        final errorBody = jsonDecode(res.body);
        String errorMsg = errorBody['title'] ?? errorBody['errors']?.toString() ?? "فشل الحفظ";
        _showErrorPopup(errorMsg);
      }
    } catch (e) {
      _showErrorPopup("حدث خطأ غير متوقع: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ======= التقويمات =======
  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        if (isStart) _startDate = date; else _endDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1020) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 20),
            _buildLabel("اختر مركبة"),
            _buildCarDropdown(isDark),
            const SizedBox(height: 15),
            _buildLabel("عنوان التذكير *"),
            _buildTextField(_nameController, "مثلاً: تغيير الزيت", isDark),
            const SizedBox(height: 15),
            _buildLabel("ملاحظات"),
            _buildTextField(_descController, "اختياري...", isDark, maxLines: 2),
            const SizedBox(height: 20),
            _buildFormGrid(isDark),
            const SizedBox(height: 20),
            _buildFrequencySection(isDark, primaryColor),
            if (_frequencyType == "4") _buildCustomFrequency(isDark),
            const SizedBox(height: 30),
            _buildSaveButton(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        const Text("إنشاء تذكير جديد", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFormGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDateTimePicker("تاريخ الانتهاء", _endDate == null ? "غير محدد" : DateFormat('yyyy/MM/dd').format(_endDate!), () => _pickDate(false), isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildDateTimePicker("تاريخ البدء *", DateFormat('yyyy/MM/dd').format(_startDate), () => _pickDate(true), isDark)),
          ],
        ),
        const SizedBox(height: 10),
        _buildDateTimePicker("وقت الإشعار", _notifTime.format(context), () async {
          final time = await showTimePicker(context: context, initialTime: _notifTime);
          if (time != null) setState(() => _notifTime = time);
        }, isDark),
      ],
    );
  }

  Widget _buildFrequencySection(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1A233A) : Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _frequencyType,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: "0", child: Text("مرة واحدة فقط", textAlign: TextAlign.right)),
            DropdownMenuItem(value: "1", child: Text("كل يوم")),
            DropdownMenuItem(value: "2", child: Text("كل أسبوع")),
            DropdownMenuItem(value: "3", child: Text("كل شهر")),
            DropdownMenuItem(value: "4", child: Text("تكرار مخصص")),
          ],
          onChanged: (v) => setState(() => _frequencyType = v!),
        ),
      ),
    );
  }

  Widget _buildCustomFrequency(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Expanded(child: _buildTextField(_intervalValueController, "العدد", isDark, isNumber: true)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<int>(
              value: _intervalUnit,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text("أيام")),
                DropdownMenuItem(value: 1, child: Text("أسابيع")),
                DropdownMenuItem(value: 2, child: Text("شهور")),
                DropdownMenuItem(value: 3, child: Text("سنوات")),
              ],
              onChanged: (v) => setState(() => _intervalUnit = v!),
            ),
          ),
          const Text(" يتكرر كل: "),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A233A) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1A233A) : Colors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedCar,
          isExpanded: true,
          items: _cars.map((c) => DropdownMenuItem(value: c as Map<String, dynamic>, child: Text("${c['brand']} ${c['model']} (${c['year']})"))).toList(),
          onChanged: (v) => setState(() => _selectedCar = v),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));

  Widget _buildTextField(TextEditingController controller, String hint, bool isDark, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? const Color(0xFF1A233A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إضافة التذكير", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}