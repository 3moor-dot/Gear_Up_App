import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:gear_up_app/pages/Notification/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  // 🔥 دالة الدخول التلقائي الآمنة
  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");
    final data = prefs.getString("userData");

    if (token != null && data != null) {
      try {
        final user = jsonDecode(data);
        // قراءة الـ role بشكل آمن وتحويله لـ int حتى لو محفوظ بصيغة تانية
        int roleId = 1;
        if (user["role"] != null) {
          roleId = int.tryParse(user["role"].toString()) ?? 1;
        }
        
        // تشغيل سيرفيس الإشعارات تلقائياً والتطبيق بيفتح
        if (mounted) {
          Provider.of<NotificationService>(context, listen: false)
              .init(userToken: token, role: roleId)
              .catchError((e) => print("Notification Auto-Init Error: $e"));
        }
        
        _navigate(roleId);
      } catch (e) {
        print("Auto login error: $e");
      }
    }
  }

  // 🔥 دالة التنقل المحدثة لاستقبال dynamic وحمايتها من الـ Null
  void _navigate(dynamic role) {
    if (!mounted) return;

    // تحويل آمن للـ role إلى int مهما كان نوعه القادم (String أو int أو null)
    int roleId = 1; 
    if (role != null) {
      roleId = int.tryParse(role.toString()) ?? 1;
    }

    print("🔀 Navigating based on role ID: $roleId");

    if (roleId == 3) {
      Navigator.pushReplacementNamed(context, "/admin/admindashboard");
    } else if (roleId == 2) {
      Navigator.pushReplacementNamed(context, "/mechanics/machineprofile");
    } else {
      Navigator.pushReplacementNamed(context, "/customer/profilesettings");
    }
  }

  // 🔥 دالة تسجيل الدخول بعد حمايتها من الـ Type Mismatch
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("برجاء ملء جميع الحقول")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": email,
          "password": password,
          "rememberMe": true,
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final token = resData["token"];
        final user = resData["user"];

        if (token != null && user != null) {
          // تحويل الـ role القادم من الـ API فوراً لـ int
          int roleId = 1;
          if (user["role"] != null) {
            roleId = int.tryParse(user["role"].toString()) ?? 1;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("userToken", token);
          await prefs.setString("userData", jsonEncode(user));

          // ربط وتشغيل سيرفيس الإشعارات فوراً بالـ Token والـ Role الصح
          if (mounted) {
            await Provider.of<NotificationService>(context, listen: false)
                .init(userToken: token, role: roleId)
                .catchError((e) => print("Notification Login-Init Error: $e"));
          }

          _navigate(roleId);
        } else {
          _showError("بيانات المستخدم غير مكتملة من السيرفر");
        }
      } else {
        _showError("فشل تسجيل الدخول، تأكد من البيانات");
      }
    } catch (e) {
      _showError("حدث خطأ في الاتصال بالسيرفر");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "تسجيل الدخول",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _input(
                  controller: emailController,
                  hint: "البريد الإلكتروني أو رقم الهاتف",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 15),
                _input(
                  controller: passwordController,
                  hint: "كلمة المرور",
                  icon: Icons.lock_outline,
                  obscure: !showPassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "تسجيل الدخول",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ليس لديك حساب؟"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/register");
                      },
                      child: const Text("إنشاء حساب"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF1F5FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}