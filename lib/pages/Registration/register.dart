import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String role = "client"; 
  int step = 1; 
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers للتحكم في النصوص
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // حالة إخفاء كلمة المرور افتراضياً

  final primaryColor = const Color(0xFF137FEC);

  // دالة إرسال البيانات للـ API
  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // تحويل الدور إلى رقم: 1 للعميل، 2 للميكانيكي
    final int roleNumber = role == "client" ? 1 : 2;

    final Map<String, dynamic> body = {
      "firstName": _firstNameController.text.trim(),
      "lastName": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "phone": _phoneController.text.trim(),
      "role": roleNumber,
      "customerLocation": {"latitude": 0, "longitude": 0},
      "mechanicLocation": {"latitude": 0, "longitude": 0},
    };

    try {
      final response = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/users/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // نجاح التسجيل
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // معالجة الخطأ القادم من السيرفر
        String msg = "فشل التسجيل";
        if (data != null) {
          if (data['errors'] != null) {
            msg = (data['errors'] as Map).values.expand((e) => e).join(" | ");
          } else {
            msg = data['message'] ?? data['title'] ?? "حدث خطأ غير معروف";
          }
        }
        throw Exception(msg);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F1323), const Color(0xFF101922)]
                  : [const Color(0xFFEAF4FF), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1F2D) : const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "إنشاء حسابك",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step == 1 ? "بياناتك الأساسية" : "اختر نوع الحساب لإتمام العملية",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Steps مع أنيميشن سلس
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: step == 1 ? _buildStep1(isDark) : _buildStep2(isDark),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        _buildErrorBox(_errorMessage!),
                      ],

                      const SizedBox(height: 30),

                      // الأزرار
                      Row(
                        children: [
                          if (step == 2) ...[
                            Expanded(
                              flex: 1,
                              child: TextButton(
                                onPressed: _isLoading ? null : () => setState(() => step = 1),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                                  minimumSize: const Size(0, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text("السابق", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading 
                                ? null 
                                : (step == 1 ? () => setState(() => step = 2) : _handleRegister),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 5,
                                shadowColor: primaryColor.withOpacity(0.4),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    step == 1 ? "متابعة" : "إنشاء الحساب الآن",
                                    style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      _buildLoginLink(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // الخطوة 1: المدخلات
 Widget _buildStep1(bool isDark) {
  return Column(
    key: const ValueKey(1),
    children: [
      Row(
        children: [
          Expanded(child: _buildInputField("الاسم الأول", Icons.person, "الاسم الأول", isDark, controller: _firstNameController)),
          const SizedBox(width: 12),
          Expanded(child: _buildInputField("العائلة", Icons.person, "العائلة", isDark, controller: _lastNameController)),
        ],
      ),
      _buildInputField("رقم الهاتف", Icons.phone, "20xxxxxxxx+", isDark, controller: _phoneController),
      _buildInputField("البريد الإلكتروني", Icons.email, "example@mail.com", isDark, controller: _emailController),
      
      // --- حقل كلمة المرور المحدث ---
      _buildInputField(
        "كلمة المرور", 
        Icons.lock, 
        "********", 
        isDark, 
        isPassword: _obscurePassword, // نستخدم المتغير هنا
        controller: _passwordController,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword; // عكس الحالة عند الضغط
            });
          },
        ),
      ),
    ],
  );
}

  // الخطوة 2: اختيار الدور (Cards كما في React)
  Widget _buildStep2(bool isDark) {
    return Column(
      key: const ValueKey(2),
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            _roleCard(
              label: "سجل كعميل",
              icon: Icons.person_pin,
              isSelected: role == "client",
              activeColor: Colors.black,
              onTap: () => setState(() => role = "client"),
              isDark: isDark,
            ),
            const SizedBox(width: 15),
            _roleCard(
              label: "سجل كميكانيكي",
              icon: Icons.build_circle,
              isSelected: role == "mechanic",
              activeColor: primaryColor,
              onTap: () => setState(() => role = "mechanic"),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          role == "client" ? "ستتمكن من طلب خدمات الصيانة فوراً" : "سنطلب منك بيانات ورشتك في الخطوة القادمة داخل التطبيق",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  // مكون بطاقة الدور المنبثقة
  Widget _roleCard({required String label, required IconData icon, required bool isSelected, required Color activeColor, required VoidCallback onTap, required bool isDark}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? Colors.white10 : Colors.grey.shade300),
              width: 2,
            ),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 45),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // صندوق الأخطاء
  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
    );
  }

  // حقل إدخال احترافي
 Widget _buildInputField(
  String label, 
  IconData icon, 
  String hint, 
  bool isDark, {
  bool isPassword = false, 
  required TextEditingController controller,
  Widget? suffixIcon, // إضافة باراميتر للأيقونة الجانبية
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword, // سيتم التحكم به من الخارج
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7), size: 20),
            
            // --- إضافة زر العين هنا ---
            suffixIcon: suffixIcon, 
            
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryColor, width: 1.5)),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildLoginLink(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/'),
      child: Text.rich(
        TextSpan(
          text: "لديك حساب؟ ",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          children: [
            TextSpan(text: "تسجيل الدخول", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}