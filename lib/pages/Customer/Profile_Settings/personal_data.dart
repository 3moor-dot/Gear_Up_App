import 'package:flutter/material.dart';

class PersonalDataTab extends StatelessWidget {
  const PersonalDataTab({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const Text("البيانات الشخصية الأساسية", 
              textAlign: TextAlign.right,
              style: TextStyle(color: Color(0xFF137FEC), fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 30),
            
            // قسم رفع الصورة
            _buildImagePicker(primaryColor),
            
            const SizedBox(height: 30),

            // الحقول (بناءً على الـ inputStyle في React)
            _buildCustomInput("الاسم الكامل", Icons.person),
            _buildCustomInput("رقم الهاتف", Icons.phone),
            _buildCustomInput("البريد الإلكتروني", Icons.email),
            _buildCustomInput("العنوان بالتفصيل", Icons.location_on),
            _buildCustomInput("البلد", Icons.map),
            
            const SizedBox(height: 30),

            // أزرار الحفظ
            Row(
              children: [
                Expanded(child: _buildActionButton("حفظ التغيرات", primaryColor, Colors.white, Icons.save)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton("إلغاء", const Color(0xFF2D3342), Colors.white, null)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(Color color) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.1), width: 4),
                color: Colors.orange.withOpacity(0.1),
              ),
              child: const Center(child: Text("صورة", style: TextStyle(color: Colors.grey))),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: color,
                radius: 18,
                child: const Icon(Icons.cloud_upload, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text("تحميل صورة الملف الشخصي", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildCustomInput(String hint, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextField(
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF137FEC).withOpacity(0.8), // نفس الستايل الداكن في React
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          hintStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
        ),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(String label, Color bg, Color text, IconData? icon) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: text, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}