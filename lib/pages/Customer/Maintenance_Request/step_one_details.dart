import 'package:flutter/material.dart';

class StepOneDetails extends StatefulWidget {
  final VoidCallback onNext;
  const StepOneDetails({super.key, required this.onNext});

  @override
  State<StepOneDetails> createState() => _StepOneDetailsState();
}

class _StepOneDetailsState extends State<StepOneDetails> {
  // حالات التحكم (State) مثل الـ React
  String selectedVehicle = "تسلا موديل 3";
  String serviceType = "خدمة طارئة";
  String requestedService = "التشخيص";
  String location = "في الورشة";
  
  final primaryColor = const Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- قسم اختيار المركبة ---
        _sectionTitle("اختر مركبة"),
        Row(
          children: [
            _selectableCard(
              title: "فورد إف-150", 
              sub: "ABC 5678 • 2019", 
              isSelected: selectedVehicle == "فورد إف-150",
              onTap: () => setState(() => selectedVehicle = "فورد إف-150")
            ),
            const SizedBox(width: 10),
            _selectableCard(
              title: "تسلا موديل 3", 
              sub: "XYZ 1234 • 2022", 
              isSelected: selectedVehicle == "تسلا موديل 3",
              onTap: () => setState(() => selectedVehicle = "تسلا موديل 3")
            ),
          ],
        ),

        const SizedBox(height: 25),

        // --- قسم نوع الخدمة ---
        _sectionTitle("نوع الخدمة"),
        Row(
          children: [
            _selectableCard(
              title: "خدمة مجدولة", 
              sub: "في وقت محدد مسبقاً", 
              isSelected: serviceType == "خدمة مجدولة",
              onTap: () => setState(() => serviceType = "خدمة مجدولة")
            ),
            const SizedBox(width: 10),
            _selectableCard(
              title: "خدمة طارئة", 
              sub: "تتطلب تدخل سريع", 
              isSelected: serviceType == "خدمة طارئة",
              onTap: () => setState(() => serviceType = "خدمة طارئة")
            ),
          ],
        ),

        const SizedBox(height: 25),

        // --- قسم التاريخ والوقت ---
        _sectionTitle("التوقيت المفضل"),
        Row(
          children: [
            _buildDateTimeInput(label: "الوقت المفضل", icon: Icons.access_time, isDark: isDark),
            const SizedBox(width: 15),
            _buildDateTimeInput(label: "التاريخ المفضل", icon: Icons.calendar_month, isDark: isDark),
          ],
        ),

        const SizedBox(height: 25),

        // --- قسم المشكلة ---
        _sectionTitle("المشكلة"),
        TextField(
          maxLines: 4,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: "صف المشكلة التي تواجهها...",
            filled: true,
            fillColor: primaryColor.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.image, size: 18),
            label: const Text("تحميل صورة المشكلة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        const SizedBox(height: 25),

        // --- قسم الخدمات المطلوبة (الأيقونات) ---
        _sectionTitle("الخدمة المطلوبة"),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _serviceIconCard("تغيير الزيت", "🛢️", requestedService == "تغيير الزيت"),
            _serviceIconCard("إصلاح الجسم", "🔨", requestedService == "إصلاح الجسم"),
            _serviceIconCard("الإطارات", "🛞", requestedService == "الإطارات"),
            _serviceIconCard("التشخيص", "🛠️", requestedService == "التشخيص"),
          ],
        ),

        const SizedBox(height: 40),

        // --- أزرار التحكم ---
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("الخطوة التالية", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text("إلغاء", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Widgets مساعدة بناءً على الـ React Components ---

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _selectableCard({required String title, required String sub, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20) else Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 5),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeInput({required String label, required IconData icon, required bool isDark}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primaryColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Text("اختر...", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(icon, color: primaryColor, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceIconCard(String title, String icon, bool active) {
    return GestureDetector(
      onTap: () => setState(() => requestedService = title),
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.white : primaryColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: active ? primaryColor : Colors.transparent, width: 2),
          boxShadow: active ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: active ? primaryColor : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}