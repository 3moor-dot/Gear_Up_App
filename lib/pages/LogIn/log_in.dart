import 'package:flutter/material.dart';
import 'dart:convert'; // لتحويل البيانات لـ JSON
import 'package:http/http.dart' as http; // لطلبات الـ API
import 'package:shared_preferences/shared_preferences.dart'; // لتخزين التوكن

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. تعريف المتحكمات (Controllers) كما في useState
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. منطق تسجيل الدخول (نفس دالة handleLogin في React)
  Future<void> _handleLogin() async {
    final String emailOrPhone = _emailOrPhoneController.text.trim();
    final String password = _passwordController.text.trim();

    if (emailOrPhone.isEmpty || password.isEmpty) {
      _showError("برجاء إدخال البريد الإلكتروني وكلمة المرور");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://gearupapp.runasp.net/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": emailOrPhone,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // حفظ التوكن في الشيرد بريفرنسز (بديل sessionStorage)
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String token = data['token'] ?? data['data']?['token'] ?? "";
        await prefs.setString('userToken', token);

        // استخراج الـ Role
        final int userRole = data['role'] ?? data['data']?['role'] ?? 1;

        // منطق التوجيه بناءً على الرتبة (نفس منطق React)
        if (!mounted) {
          return;
        } else if (userRole == 2) {
          Navigator.pushReplacementNamed(context, '/mechanic/dashboard');
        } else if (userRole == 1) {
          Navigator.pushReplacementNamed(context, '/customer/dashboard');
        } 
      } else {
        _showError(data['message'] ?? "بيانات الدخول غير صحيحة");
      }
    } catch (err) {
      _showError("فشل الاتصال بالسيرفر، تأكد من اتصالك بالإنترنت");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دالة لإظهار رسائل الخطأ (بديل alert)
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // SECTION IMAGE (نفس التصميم السابق)
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/car.png',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 180,
                          color: primaryColor.withOpacity(0.1),
                          child: Icon(Icons.directions_car, size: 100, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "العناية الذكية بالسيارة، بشكل مبسط",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                "مرحباً بعودتك 👋",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // EMAIL INPUT
              _buildLabel("البريد الإلكتروني أو رقم الهاتف", null),
              _buildTextField(
                controller: _emailOrPhoneController,
                hint: "ادخل البريد الإلكتروني أو رقم الهاتف",
                icon: Icons.phone_android,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // PASSWORD INPUT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("كلمة المرور", null),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: Text(
                      "هل نسيت كلمة السر؟",
                      style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              _buildTextField(
                controller: _passwordController,
                hint: "ادخل كلمة المرور",
                icon: Icons.lock_outline,
                isDark: isDark,
                isPassword: true,
              ),

              const SizedBox(height: 32),

              // LOGIN BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "تسجيل الدخول",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),

              // REGISTER LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("  ليس لديك حساب؟"),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      " قم بالتسجيل",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets المحدثة لاستقبال الـ Controller ---

  Widget _buildLabel(String text, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.1)
            : const Color(0xFF8EC1F5).withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        textAlign: TextAlign.right,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}