import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // متغيرات للتحكم في إظهار وإخفاء كلمة المرور
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // ICON Illustration
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, size: 70, color: primaryColor),
              ),

              const SizedBox(height: 32),

              // Header
              Text(
                "إعادة تعيين كلمة المرور",
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "أدخل كلمة المرور الجديدة لتأمين حسابك. تأكد من استخدام كلمة مرور قوية.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5
                ),
              ),

              const SizedBox(height: 40),

              // NEW PASSWORD FIELD
              _buildPasswordField(
                label: "كلمة المرور الجديدة",
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                isDark: isDark,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 20),

              // CONFIRM PASSWORD FIELD
              _buildPasswordField(
                label: "تأكيد كلمة المرور الجديدة",
                isVisible: _isConfirmVisible,
                onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                isDark: isDark,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 40),

              // SUBMIT BUTTON
              ElevatedButton(
                onPressed: () {
                  // هنا نضع منطق العودة لصفحة تسجيل الدخول بعد النجاح
                  _showSuccessDialog(context, primaryColor);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "تحديث كلمة المرور",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildPasswordField({
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF137FEC).withOpacity(0.1) : const Color(0xFFE8F3FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            obscureText: !isVisible,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "********",
              prefixIcon: IconButton(
                icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تم بنجاح", textAlign: TextAlign.center),
        content: const Text("تم تحديث كلمة المرور الخاصة بك بنجاح، يمكنك الآن تسجيل الدخول.", textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text("تسجيل الدخول", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}