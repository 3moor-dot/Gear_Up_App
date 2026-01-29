import 'package:flutter/material.dart';

class CreateReminderModal extends StatefulWidget {
  const CreateReminderModal({super.key});

  @override
  State<CreateReminderModal> createState() => _CreateReminderModalState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateReminderModal(),
    );
  }
}

class _CreateReminderModalState extends State<CreateReminderModal> {
  String selectedRepeat = 'period';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);
    final bgColor = isDark ? const Color(0xFF0B1020) : const Color(0xFFE5F1FD);
    final cardColor = isDark ? const Color(0xFF137FEC).withOpacity(0.1) : Colors.blue.withOpacity(0.05);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHeader(context, isDark),
                  const SizedBox(height: 30),
                  _buildLabel("اختر مركبة", isDark),
                  _buildDropdownField(["2021 Tesla Model 3", "2022 Toyota RAV4"], isDark),
                  const SizedBox(height: 20),
                  _buildLabel("عنوان التذكير", isDark),
                  _buildTextField("على سبيل المثال: تغيير الزيت...", isDark),
                  const SizedBox(height: 25),
                  
                  // الحاوية الزرقاء
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("تاريخ التذكير", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        _buildRadioOption("لمرة واحدة فقط", "once"),
                        _buildRadioOption("يتكرر", "repeat"),
                        _buildRadioOption("يتكرر لفترة محددة", "period"),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context),
                                child: _buildDateTimePicker(Icons.access_time, selectedTime.format(context), isDark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context),
                                child: _buildDateTimePicker(Icons.calendar_month, "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", isDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildLabel("ملاحظات إضافية", isDark),
                  _buildTextField("أضف أي تفاصيل محددة...", isDark, maxLines: 3),
                  const SizedBox(height: 35),
                  _buildSaveButton(primaryColor),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- دوال مساعدة محدثة ---

  Widget _buildHeader(BuildContext context, bool isDark) {
     return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("تذكير جديد بالصيانة", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            const Text("قم بإعداد تنبيه مخصص لحالة سيارتك", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("حفظ التذكير", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // (بقيت الدوال _buildLabel و _buildTextField و _buildDropdownField و _buildRadioOption و _buildDateTimePicker كما هي في كودك الأصلي)
  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(String hint, bool isDark, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A233A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items[0],
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {},
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, String value) {
    return InkWell(
      onTap: () => setState(() => selectedRepeat = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(title, style: const TextStyle(fontSize: 13)),
            Radio<String>(
              value: value,
              groupValue: selectedRepeat,
              activeColor: const Color(0xFF137FEC),
              onChanged: (v) => setState(() => selectedRepeat = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1020) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF137FEC)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}