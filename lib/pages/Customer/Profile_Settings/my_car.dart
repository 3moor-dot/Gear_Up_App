import 'package:flutter/material.dart';

class MyCarsTab extends StatelessWidget {
  const MyCarsTab({super.key});

  final String inputStyleColor = "#137FEC"; // اللون الأساسي

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "بيانات سياراتي",
            style: TextStyle(color: Color(0xFF137FEC), fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 30),

          // --- قسم إضافة سيارة (تصميم عرضي احترافي) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الجهة اليسرى: الحقول
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput("موديل السيارة")),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput("اسم السيارة")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInput("رقم لوحة بيانات")),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput("سنة التصنيع")),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // الجهة اليمنى: صورة السيارة
              _buildCarImagePicker(primaryColor),
            ],
          ),

          const SizedBox(height: 25),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("إضافة سيارة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),

          const SizedBox(height: 40),
          // الخط المنقط
          _buildDottedDivider(),
          const SizedBox(height: 40),

          // --- قائمة السيارات (تصميم الكبسولة) ---
          _buildCarCard(
            "2022 Toyota RAV4",
            "https://images.unsplash.com/photo-1583121274602-3e2820c69888?q=80&w=2070&auto=format&fit=crop",
            primaryColor,
          ),
        ],
      ),
    );
  }

  // ويدجت رفع الصورة (الدائرة مع الأيقونة)
  Widget _buildCarImagePicker(Color primaryColor) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFDEBD0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5F1FD), width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Opacity(
                  opacity: 0.4,
                  child: Image.network("https://cdn-icons-png.flaticon.com/512/744/744465.png", fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: primaryColor,
                radius: 18,
                child: const Icon(Icons.cloud_upload, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text("تحميل صورة", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  // تصميم الحقول (InputStyle)
  Widget _buildInput(String hint) {
    return TextField(
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF137FEC).withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  // ويدجت قائمة السيارات (الكبسولة)
  Widget _buildCarCard(String name, String imgUrl, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // صورة مصغرة
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 80,
              height: 50,
              color: Colors.white24,
              child: Image.network(imgUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 15),
          // اسم السيارة
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15)),
          const Spacer(),
          // أزرار التحكم
          Row(
            children: [
              _circleBtn(Icons.edit, Colors.blue),
              const SizedBox(width: 8),
              _circleBtn(Icons.delete, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // الخط المنقط
  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.blue.withOpacity(0.3),
            height: 2,
          ),
        ),
      ),
    );
  }
}