import 'package:flutter/material.dart';

class SecuritySettingsTab extends StatelessWidget {
  const SecuritySettingsTab({super.key});

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
            const Text("كلمة المرور", textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF137FEC), fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 30),
            
            _buildPasswordField("كلمة المرور الحالية"),
            _buildPasswordField("كلمة المرور الجديدة"),
            _buildPasswordField("تأكيد كلمة المرور الجديدة"),
            
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text("حفظ التغيرات", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                shadowColor: primaryColor.withOpacity(0.5),
              ),
            ),
            
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: const Text(
                "* تأكد من اختيار كلمة مرور قوية تحتوي على رموز وأرقام لحماية حسابك بشكل أفضل.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF137FEC).withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}