import 'package:flutter/material.dart';

class StepProgressWidget extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepChange;

  const StepProgressWidget({super.key, required this.currentStep, required this.onStepChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentStep == 1 ? "طلب صيانة" : "حجز صيانة",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const Text("قم بإنشاء ومتابعة طلبات الصيانة بسهولة", 
          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        Row(
          children: [
            _buildStepItem(1, "الخطوة 1", "التفاصيل", Icons.edit_note),
            const SizedBox(width: 15),
            _buildStepItem(2, "الخطوة 2", "جدول", Icons.calendar_month),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem(int step, String title, String sub, IconData icon) {
    bool isActive = currentStep == step;
    return Expanded(
      child: GestureDetector(
        onTap: () => onStepChange(step),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF137FEC) : const Color(0xFF2D3342),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(sub, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}