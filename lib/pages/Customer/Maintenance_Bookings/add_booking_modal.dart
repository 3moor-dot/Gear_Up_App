import 'package:flutter/material.dart';

class AddBookingModal extends StatefulWidget {
  const AddBookingModal({super.key});

  @override
  State<AddBookingModal> createState() => _AddBookingModalState();
}

class _AddBookingModalState extends State<AddBookingModal> {
  // متغيرات لتخزين القيم المختارة
  String? selectedMechanic;
  String? selectedService;
  String? selectedCar;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final primaryColor = const Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1020) : const Color(0xFFE5F1FD);
    final inputBg = isDark ? const Color(0xFF137FEC).withOpacity(0.2) : const Color(0xFF93C5FD);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // للتعامل مع لوحة المفاتيح
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب العلوي (أنيق للموبايل)
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "إضافة حجز جديد",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // الحقول
            _buildDropdownField("الميكانيكي", ["علي جمال", "أحمد محمد", "محمود حسن"], inputBg),
            _buildDropdownField("الخدمة", ["تغيير زيت", "فحص فرامل", "صيانة دورية"], inputBg),
            _buildDropdownField("اختيار السيارة", ["Toyota RAV4 2022", "Honda Civic 2021"], inputBg),

            // التاريخ
            _buildInteractiveField(
              "التاريخ",
              selectedDate == null ? "اختر التاريخ" : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              Icons.calendar_month,
              inputBg,
              () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),

            // التوقيت
            _buildInteractiveField(
              "التوقيت",
              selectedTime == null ? "اختر الوقت" : selectedTime!.format(context),
              Icons.access_time_filled,
              inputBg,
              () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
            ),

            const SizedBox(height: 30),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم إرسال طلبك بنجاح!", textAlign: TextAlign.center)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                ),
                child: const Text(
                  "إرسال طلب جديد",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت حقول القوائم المنسدلة
  Widget _buildDropdownField(String label, List<String> options, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                dropdownColor: const Color(0xFF137FEC),
                hint: const Text("اختر من القائمة...", style: TextStyle(color: Colors.white70, fontSize: 13)),
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت الحقول التفاعلية (تاريخ ووقت)
  Widget _buildInteractiveField(String label, String value, IconData icon, Color bgColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const Spacer(),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}