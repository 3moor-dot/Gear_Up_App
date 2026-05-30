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

  // 🔥 دالة الدخول التلقائي المطابقة تماماً لمنطق الـ React (Session/Storage Check)
  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");
    final data = prefs.getString("userData");

    if (token != null && data != null) {
      try {
        final user = jsonDecode(data);

        // استخراج الـ role بشكل آمن ومطابق تماماً للـ React
        int roleId = 1;
        if (user["role"] != null) {
          roleId = int.tryParse(user["role"].toString()) ?? 1;
        }

        if (mounted) {
          final notificationService = Provider.of<NotificationService>(
            context,
            listen: false,
          );

          // تشغيل سيرفيس الإشعارات الفورية تلقائياً والتطبيق بيفتح
          await notificationService
              .init(userToken: token, role: roleId)
              .catchError((e) => print("🔔 Notification Auto-Init Error: $e"));

          // رفع الـ FCM Token الخاص بالجهاز لتحديث الـ Backend فوراً
          await notificationService
              .uploadDeviceToken(token)
              .catchError((e) => print("📱 Token Auto-Upload Error: $e"));
        }

        _navigate(roleId);
      } catch (e) {
        print("Auto login error: $e");
      }
    }
  }

  // 🔀 دالة التنقل والتوجيه المبنية على الـ Role ID المتطابق مع الـ React
  void _navigate(dynamic role) {
    if (!mounted) return;

    int roleId = 1;
    if (role != null) {
      roleId = int.tryParse(role.toString()) ?? 1;
    }

    print("🔀 Navigating based on role ID: $roleId");

    // التوجيه للمسارات المتطابقة تماماً مع بنية الـ React Dashboard
    if (roleId == 3) {
      Navigator.pushReplacementNamed(context, "/admin/admindashboard");
    } else if (roleId == 2) {
      Navigator.pushReplacementNamed(
        context,
        "/mechanics/machineprofile",
      ); // تعديل المسار ليتطابق مع الـ Routes الجديدة
    } else {
      Navigator.pushReplacementNamed(
        context,
        "/customer/profilesettings",
      ); // تعديل المسار ليتطابق مع الـ Dashboard الرئيسي للعميل
    }
  }

  // 🚀 دالة تسجيل الدخول المحدثة والمرنة تماماً مع الـ API
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showCustomSnackBar(
        title: "بيانات ناقصة",
        message: "يرجى إدخال البريد الإلكتروني وكلمة المرور",
        isWarning: true,
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

      final resData = jsonDecode(response.body);
      print(
        "🔍 السيرفر أرجع هذه البيانات بالظبط: $resData",
      ); // لمتابعة الـ Payload في الـ Debugger

      if (response.statusCode == 200) {
        // قراءة مرنة جداً للـ Token والـ User بأي صيغة يرسلها الـ .NET Core
        final token =
            resData["token"] ??
            resData["accessToken"] ??
            resData["data"]?["token"];
        final user = resData["user"] ?? resData["data"]?["user"] ?? resData;

        if (token != null) {
          // إذا كان الـ user عبارة عن الـ Object الرئيسي بالكامل أو جزء منه
          final Map<String, dynamic> userMap = user is Map<String, dynamic>
              ? user
              : {};

          // استخراج الـ Role بشكل آمن
          int roleId = 1;
          if (userMap["role"] != null) {
            roleId = int.tryParse(userMap["role"].toString()) ?? 1;
          } else if (resData["role"] != null) {
            roleId = int.tryParse(resData["role"].toString()) ?? 1;
          }

          // حفظ البيانات في الكاش (SharedPreferences)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("userToken", token);
          await prefs.setString(
            "userData",
            jsonEncode(userMap.isNotEmpty ? userMap : resData),
          );

          if (mounted) {
            _showCustomSnackBar(
              title: "تم تسجيل الدخول بنجاح",
              message: "مرحباً بعودتك إلى منصة GearUp 👋",
              isSuccess: true,
            );

            // تشغيل خدمات الإشعارات
            final notificationService = Provider.of<NotificationService>(
              context,
              listen: false,
            );

            await notificationService
                .init(userToken: token, role: roleId)
                .catchError(
                  (e) => print("🔔 Notification Login-Init Error: $e"),
                );

            await notificationService
                .uploadDeviceToken(token)
                .catchError((e) => print("📱 Token Login-Upload Error: $e"));
          }

          // الانتقال الفوري للـ Dashboard المناسب للـ Role
          Future.delayed(const Duration(milliseconds: 1000), () {
            _navigate(roleId);
          });
        } else {
          _showCustomSnackBar(
            title: "فشل الدخول",
            message: "السيرفر لم يقم بإرسال الـ Access Token بشكل صحيح",
          );
        }
      } else {
        _showCustomSnackBar(
          title: "فشل الدخول",
          message:
              resData["message"] ??
              "تأكد من صحة البريد الإلكتروني أو كلمة المرور",
        );
      }
    } catch (e) {
      print("❌ Error during login parsing: $e");
      _showCustomSnackBar(
        title: "خطأ في البيانات",
        message: "حدث خطأ أثناء قراءة بيانات السيرفر",
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🎨 دالة مخصصة لعرض التنبيهات بشكل وتصميم محاكي لـ SweetAlert2 المستخدم في الـ React
  void _showCustomSnackBar({
    required String title,
    required String message,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;

    Color backgroundColor = const Color(0xFF131A2E); // Dark Mode Default
    if (isSuccess) backgroundColor = Colors.green.shade600;
    if (isWarning) backgroundColor = const Color(0xFFFFB020);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(15),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: SafeArea(
            child: Directionality(
              textDirection: TextDirection
                  .rtl, // دعم الـ RTL الافتراضي للـ UI بالكامل مثل الويب
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "تسجيل الدخول",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "مرحباً بعودتك 👋",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _input(
                    controller: emailController,
                    hint: "البريد الإلكتروني أو رقم الهاتف",
                    icon: Icons
                        .phone_android_outlined, // تغيير الأيقونة لتطابق الـ FaPhone في الـ React
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
                      backgroundColor: const Color(
                        0xFF2563EB,
                      ), // تحديث اللون ليتطابق مع الـ React (#2563EB)
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("ليس لديك حساب؟"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/register");
                        },
                        child: const Text(
                          "إنضم إلينا الآن", // تحديث الجملة لتطابق الـ الـ React تماماً
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF1F5FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
    );
  }
}
