import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // تعريف وحدات التحكم والحالات
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final Color primaryColor = const Color(0xFF137FEC);

  // دالة ربط الباك آند (نفس منطق كود React)
  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();

    // التحقق من إدخال البريد
    if (email.isEmpty) {
      setState(() => _errorMessage = "يرجى إدخال البريد الإلكتروني");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/auth/send-password-reset-email"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // في حالة النجاح ننتقل لصفحة التأكيد
        if (mounted) {
          Navigator.pushNamed(context, '/verify-account');
        }
      } else {
        // محاولة استخراج رسالة الخطأ من السيرفر
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "حدث خطأ، يرجى المحاولة مرة أخرى");
      }
    } catch (err) {
      setState(() => _errorMessage = err.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          icon: Icon(Icons.arrow_back_ios_new, 
                color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // أيقونة توضيحية احترافية
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_reset_rounded, size: 70, color: primaryColor),
              ),

              const SizedBox(height: 32),

              // العنوان والوصف (نفس نصوص كود React)
              Text(
                "هل نسيت كلمة السر",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "أدخل عنوان البريد الإلكتروني المرتبط بحسابك، وسنرسل إليك كود التحقق لإعادة تعيين كلمة المرور.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // حقل الإدخال بتصميم مطابق لـ React
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, // للمحاذاة العربية
                children: [
                  const Text(
                    "عنوان البريد الإلكتروني",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? primaryColor.withOpacity(0.1) : const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _errorMessage != null ? Colors.red : primaryColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _emailController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "yourname@example.com",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                  // عرض رسالة الخطأ إن وجدت
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // زر الإرسال مع حالة التحميل
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: primaryColor.withOpacity(0.6),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "إرسال كود التحقق",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 30),

              // العودة لتسجيل الدخول
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "العودة إلى تسجيل الدخول",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Text("  هل تذكرت كلمة المرور؟", style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}