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
  // ======= الحالات (States) =======
  bool _isLoading = false;
  List<dynamic> _cars = [];
  Map<String, dynamic>? _selectedCar;

  // بيانات النموذج (Form Data)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _intervalValueController = TextEditingController(
    text: "1",
  );

  DateTime _startDate = DateTime.now();
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);
  String _frequencyType = "0"; // 0=Once, 1=Daily, 2=Weekly, 3=Monthly, 4=Custom
  int _intervalUnit = 0; // 0=Days, 1=Weeks, 2=Months, 3=Years

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  // ======= جلب السيارات من الـ API =======
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

  // ======= إرسال البيانات للـ Backend =======
  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء البيانات الأساسية")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    // تجهيز الوقت بصيغة HH:mm
    final String formattedTime =
        "${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}";

    final payload = {
      "carId": int.tryParse(_selectedCar!['id'].toString()) ?? 0,
      "name": _nameController.text,
      "description": _descController.text,
      "startDate": _startDate.toIso8601String(),
      "preferredNotificationTime": formattedTime,
      "frequencyType": _frequencyType == "4" ? 5 : int.parse(_frequencyType),
      "intervalValue": _frequencyType == "4"
          ? int.parse(_intervalValueController.text)
          : 0,
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
        Navigator.pop(context);
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      debugPrint("Save Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل الحفظ: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ======= أدوات اختيار التاريخ والوقت =======
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notifTime,
    );
    if (time != null) setState(() => _notifTime = time);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            _buildHeader(context, isDark),
            const SizedBox(height: 25),

            _buildLabel("اختر مركبة", isDark),
            _buildCarDropdown(isDark),

            const SizedBox(height: 15),
            _buildLabel("عنوان التذكير", isDark),
            _buildTextField(_nameController, "تغيير زيت، فحص فرامل...", isDark),

            const SizedBox(height: 15),
            _buildLabel("ملاحظات", isDark),
            _buildTextField(
              _descController,
              "أضف تفاصيل إضافية...",
              isDark,
              maxLines: 2,
            ),

            const SizedBox(height: 25),
            _buildBlueCard(primaryColor, isDark),

            if (_frequencyType == "4") _buildCustomFrequency(isDark),

            const SizedBox(height: 30),
            _buildSaveButton(primaryColor),
          ],
        ),
      ),
    );
  }

  // ======= مكونات الواجهة (UI Components) =======

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "إضافة تذكير صيانة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "سيتم تنبيهك في الموعد المحدد",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedCar,
          isExpanded: true,
          items: _cars
              .map(
                (c) => DropdownMenuItem(
                  value: c as Map<String, dynamic>,
                  child: Text(
                    "${c['brand']} ${c['model']} (${c['year']})",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCar = v),
        ),
      ),
    );
  }

  Widget _buildBlueCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildRadioTile("مرة واحدة فقط", "0"),
          _buildRadioTile("يومياً", "1"),
          _buildRadioTile("أسبوعياً", "2"),
          _buildRadioTile("شهرياً", "3"),
          _buildRadioTile("تكرار مخصص", "4"),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(
                child: _datePickerTile(
                  Icons.access_time,
                  _notifTime.format(context),
                  _pickTime,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _datePickerTile(
                  Icons.calendar_month,
                  DateFormat('yyyy/MM/dd').format(_startDate),
                  _pickDate,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFrequency(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              value: _intervalUnit,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text("أيام")),
                DropdownMenuItem(value: 1, child: Text("أسابيع")),
                DropdownMenuItem(value: 2, child: Text("شهور")),
              ],
              onChanged: (v) => setState(() => _intervalUnit = v!),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildTextField(
              _intervalValueController,
              "العدد",
              isDark,
              isNumber: true,
            ),
          ),
          const Text(" يتكرر كل: "),
        ],
      ),
    );
  }

  // ======= دوال صغيرة مساعدة =======
  Widget _buildLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? const Color(0xFF1A233A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, String value) {
    return InkWell(
      onTap: () => setState(() => _frequencyType = value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          Radio<String>(
            value: value,
            groupValue: _frequencyType,
            onChanged: (v) => setState(() => _frequencyType = v!),
          ),
        ],
      ),
    );
  }

  Widget _datePickerTile(
    IconData icon,
    String text,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // تعديل: لون الخلفية يتغير حسب النمط
          color: isDark ? const Color(0xFF1A233A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                // تعديل: لون النص يتغير حسب النمط ليصبح واضحاً
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "حفظ التذكير",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
