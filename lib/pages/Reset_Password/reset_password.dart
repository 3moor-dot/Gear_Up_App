import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // وحدات التحكم في النصوص
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // حالات الرؤية (العين)
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // حالات النظام (نفس منطق React)
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  final Color primaryColor = const Color(0xFF137FEC);

  // دالة إرسال البيانات للباك آند
  Future<void> _handleSubmit() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 1. التحقق من الحقول (Validation)
    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = "يرجى ملء جميع الحقول");
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = "كلمتا المرور غير متطابقتين");
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = "يجب أن تكون كلمة المرور 8 أحرف على الأقل");
      return;
    }

    // 2. جلب التوكن (Token)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('reset_token');

    if (token == null) {
      setState(() => _errorMessage = "انتهت صلاحية الجلسة، يرجى البدء من جديد");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "newPassword": password,
        }),
      );

      if (response.statusCode == 200) {
        // حذف التوكن بعد النجاح
        await prefs.remove('reset_token');
        setState(() => _isSuccess = true);
        
        // التحويل لصفحة تسجيل الدخول بعد ثانيتين (نفس React)
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        });
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "حدث خطأ، يرجى المحاولة مرة أخرى");
      }
    } catch (err) {
      setState(() => _errorMessage = err.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
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
                  height: 1.5,
                  fontSize: 14
                ),
              ),

              const SizedBox(height: 40),

              // NEW PASSWORD FIELD
              _buildPasswordField(
                label: "كلمة المرور الجديدة",
                controller: _passwordController,
                isVisible: _showPassword,
                onToggle: () => setState(() => _showPassword = !_showPassword),
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // CONFIRM PASSWORD FIELD
              _buildPasswordField(
                label: "تأكيد كلمة المرور الجديدة",
                controller: _confirmPasswordController,
                isVisible: _showConfirmPassword,
                onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // Error & Success Messages
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
              
              if (_isSuccess)
                const Text("تم تغيير كلمة المرور بنجاح! جارٍ التحويل...", 
                  style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),

              const SizedBox(height: 30),

              // SUBMIT BUTTON
              ElevatedButton(
                onPressed: (_isLoading || _isSuccess) ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: primaryColor.withOpacity(0.6),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        "إرسال",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? primaryColor.withOpacity(0.1) : const Color(0xFFE8F3FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "أدخل كلمة المرور",
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              // العين جهة اليسار
              prefixIcon: IconButton(
                icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: primaryColor, size: 22),
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
}