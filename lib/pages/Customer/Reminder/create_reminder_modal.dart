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
  final TextEditingController _intervalValueController = TextEditingController(
    text: "1",
  );

  // جعل التاريخ فارغاً في البداية
  DateTime? _reminderDate;
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);
  String _frequencyType = "0";
  int _intervalUnit = 0;

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

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

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "تنبيه",
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    // التحقق من أن التاريخ تم اختياره
    if (_reminderDate == null) {
      _showErrorPopup("يرجى اختيار تاريخ التذكير أولاً");
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    final String formattedTime =
        "${_notifTime.hour.toString().padLeft(2, '0')}:${_notifTime.minute.toString().padLeft(2, '0')}";

    String formatToBackend(DateTime date) {
      final fixedDate = date.add(const Duration(hours: 12));
      return fixedDate.toIso8601String();
    }

    final payload = {
      "carId": _selectedCar!['id'],
      "name": _nameController.text,
      "description": _descController.text,
      "startDate": formatToBackend(_reminderDate!),
      "endDate": null, 
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
        if (mounted) Navigator.pop(context);
      } else {
        final errorBody = jsonDecode(res.body);
        String errorMsg =
            errorBody['title'] ??
            errorBody['errors']?.toString() ??
            "فشل الحفظ";
        _showErrorPopup(errorMsg);
      }
    } catch (e) {
      _showErrorPopup("حدث خطأ غير متوقع: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // يفضل ألا يختار تاريخاً في الماضي
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _reminderDate = date;
      });
    }
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
            _buildHeader(),
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

            // قسم التاريخ والوقت المحدث
            _buildDateAndTimeSection(isDark),

            const SizedBox(height: 20),
            _buildLabel("التكرار"),
            _buildFrequencySection(isDark),
            if (_frequencyType == "4") _buildCustomFrequency(isDark),
            const SizedBox(height: 30),
            _buildSaveButton(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndTimeSection(bool isDark) {
    return Row(
      children: [
        // خانة الوقت (يسار)
        Expanded(
          child: _buildDateTimePicker(
            "وقت الإشعار",
            _notifTime.format(context),
            () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _notifTime,
              );
              if (time != null) setState(() => _notifTime = time);
            },
            isDark,
          ),
        ),
        const SizedBox(width: 15),
        // خانة التاريخ (يمين) - تاريخ واحد فقط
        Expanded(
          child: _buildDateTimePicker(
            "تاريخ التذكير *",
            // إذا كان التاريخ نل، يظهر نص "اختر التاريخ" بدلاً من تاريخ اليوم
            _reminderDate == null
                ? "اختر التاريخ"
                : DateFormat('yyyy/MM/dd').format(_reminderDate!),
            _pickDate,
            isDark,
            isPlaceholder:
                _reminderDate == null, // لتغيير لون النص إذا كان فارغاً
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(
    String label,
    String value,
    VoidCallback onTap,
    bool isDark, {
    bool isPlaceholder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A233A) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isPlaceholder
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                // لون باهت إذا كان التاريخ لم يُختر بعد
                color: isPlaceholder
                    ? Colors.grey.shade400
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // باقي عناصر الـ UI (مختصرة للتركيز على التعديل)
  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      const Text(
        "إنشاء تذكير جديد",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  );
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Widget _buildFrequencySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _frequencyType,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: "0",
              child: Text("مرة واحدة فقط", textAlign: TextAlign.right),
            ),
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
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              _intervalValueController,
              "العدد",
              isDark,
              isNumber: true,
            ),
          ),
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

  Widget _buildCarDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedCar,
          isExpanded: true,
          items: _cars
              .map(
                (c) => DropdownMenuItem(
                  value: c as Map<String, dynamic>,
                  child: Text("${c['brand']} ${c['model']} (${c['year']})"),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCar = v),
        ),
      ),
    );
  }

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
                "إضافة التذكير",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
