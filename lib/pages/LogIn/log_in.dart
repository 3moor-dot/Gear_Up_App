import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // المتحكمات (Controllers)
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // حالات الصفحة (State)
  bool _isLoading = false;
  bool _obscurePassword = true; // للتحكم في ظهور كلمة المرور

  final Color primaryColor = const Color(0xFF137FEC);

  // دالة تسجيل الدخول
  Future<void> _handleLogin() async {
    final String emailOrPhone = _emailOrPhoneController.text.trim();
    final String password = _passwordController.text.trim();

    if (emailOrPhone.isEmpty || password.isEmpty) {
      _showMessage("برجاء ملء جميع الحقول", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": emailOrPhone,
          "password": password,
          "rememberMe": true,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        
        // 1. حفظ التوكن
        final String token = data['accessToken'] ?? "";
        await prefs.setString('userToken', token);

        // 2. استخراج وحفظ بيانات المستخدم (نفس منطق React)
        dynamic rawData = data['data'] ?? data;
        final userData = {
          "firstName": rawData['firstName']?.toString() ?? "",
          "lastName": rawData['lastName']?.toString() ?? "",
          "email": rawData['email'] ?? "",
          "phone": rawData['phone'] ?? "",
          "role": rawData['role'],
          "profileImage": rawData['profileImage'],
        };
        await prefs.setString('userData', jsonEncode(userData));

        // 3. التوجيه بناءً على الرتبة
        if (!mounted) return;
        final int role = userData['role'];

        if (role == 2) {
          Navigator.pushReplacementNamed(context, '/mechanics/machineprofile');
        } else if (role == 1) {
          Navigator.pushReplacementNamed(context, '/customer/profilesettings');
        }
      } else {
        _showMessage(data['message'] ?? "بيانات الدخول غير صحيحة", isError: true);
      }
    } catch (err) {
      _showMessage("فشل الاتصال بالسيرفر، حاول مجدداً", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1323) : Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                
                // صورة السيارة (Header Image)
                _buildHeaderImage(primaryColor),

                const SizedBox(height: 30),
                
                // الترحيب
                Text(
                  "مرحباً بعودتك 👋",
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Text(
                  "تسجيل الدخول إلى حسابك",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 40),

                // حقل البريد أو الهاتف
                _buildInputField(
                  label: "البريد الإلكتروني أو رقم الهاتف",
                  hint: "ادخل البريد الإلكتروني أو رقم الهاتف",
                  icon: Icons.phone_android_outlined,
                  controller: _emailOrPhoneController,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // حقل كلمة المرور مع زر العين
                _buildPasswordField(isDark),

                const SizedBox(height: 35),

                // زر تسجيل الدخول
                _buildLoginButton(),

                const SizedBox(height: 25),

                // رابط التسجيل
                _buildRegisterLink(isDark),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- مكونات واجهة المستخدم (Widgets) ---

  Widget _buildHeaderImage(Color primaryColor) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/car.png',
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 180,
              color: primaryColor.withOpacity(0.1),
              child: Icon(Icons.directions_car_filled, size: 80, color: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "العناية الذكية بالسيارة، بشكل مبسط",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? primaryColor.withOpacity(0.1) : const Color(0xFF8EC1F5).withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: Icon(icon, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("كلمة المرور", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/forgot-password'),
              child: Text("هل نسيت كلمة السر؟", style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? primaryColor.withOpacity(0.1) : const Color(0xFF8EC1F5).withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "ادخل كلمة المرور",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("تسجيل الدخول", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("ليس لديك حساب؟", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Text(" إنضم إلينا الآن", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}