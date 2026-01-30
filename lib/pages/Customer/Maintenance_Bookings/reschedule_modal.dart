import 'dart:ui';
import 'package:flutter/material.dart';

class RescheduleDialog extends StatefulWidget {
  const RescheduleDialog({super.key});

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final primaryColor = const Color(0xFF137FEC);
  final darkBg = const Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            // اللون الأزرق الشفاف مع الحدود (بناءً على الكود الثاني)
            color: const Color(0xFF137FEC).withOpacity(0.35),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر الإغلاق X
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white60, size: 28),
                ),
              ),

              const Text(
                "تغيير الموعد",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 30),

              // شبكة التاريخ والوقت (Grid)
              Row(
                children: [
                  // حقل التوقيت
                  Expanded(
                    child: _buildInputBox(
                      label: "التوقيت",
                      value: selectedTime == null ? "--:--" : selectedTime!.format(context),
                      icon: Icons.access_time_filled,
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setState(() => selectedTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  // حقل التاريخ
                  Expanded(
                    child: _buildInputBox(
                      label: "التاريخ",
                      value: selectedDate == null ? "00/00/00" : "${selectedDate!.day}/${selectedDate!.month}",
                      icon: Icons.calendar_month,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // أزرار التحكم (إلغاء وتغيير)
              Row(
                children: [
                  // زر تغيير الموعد
                  Expanded(
                    child: _buildButton(
                      label: "تغيير الموعد",
                      color: primaryColor,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم تغيير الموعد بنجاح!", textAlign: TextAlign.center)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر إلغاء
                  Expanded(
                    child: _buildButton(
                      label: "إلغاء",
                      color: const Color(0xFF0F1323),
                      textColor: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت بناء حقل الإدخال (التاريخ/الوقت)
  Widget _buildInputBox({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
            decoration: BoxDecoration(
              color: darkBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const Spacer(),
                Text(value, style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ويدجت بناء الزر
  Widget _buildButton({required String label, required Color color, required Color textColor, required VoidCallback onTap}) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}