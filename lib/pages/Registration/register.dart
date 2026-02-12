import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // الحالات (States)
  String role = "client"; 
  int step = 1; // 1 or 2

  final primaryColor = const Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl, // لضمان اتجاه التطبيق من اليمين لليسار
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
                  constraints: const BoxConstraints(maxWidth: 550),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1F2D) : const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TITLE
                      Text(
                        "إنشاء حسابك",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step == 1 ? "بياناتك الأساسية" : "اختر نوع الحساب لإتمام العملية",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 30),

                      // FORM STEPS (Animated)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: step == 1 ? _buildStep1(isDark) : _buildStep2(isDark),
                      ),

                      const SizedBox(height: 30),

                      // NAVIGATION BUTTONS
                      Row(
                        children: [
                          if (step == 2) ...[
                            Expanded(
                              flex: 1,
                              child: TextButton(
                                onPressed: () => setState(() => step = 1),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                  minimumSize: const Size(0, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text("السابق", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                if (step == 1) {
                                  setState(() => step = 2);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(
                                step == 1 ? "متابعة" : "إنشاء الحساب الآن",
                                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // LOGIN LINK
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/login'),
                        child: Text.rich(
                          TextSpan(
                            text: "لديك حساب؟ ",
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            children: [
                              TextSpan(
                                text: "تسجيل الدخول",
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  // --- الخطوة الأولى: البيانات الأساسية ---
  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey(1),
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("الاسم الأول", Icons.person_outline, "الاسم الأول", isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField("اسم العائلة", Icons.person_outline, "العائلة", isDark)),
          ],
        ),
        _buildInputField("رقم الهاتف", Icons.phone_android, "20xxxxxxxx+", isDark),
        _buildInputField("البريد الإلكتروني", Icons.email_outlined, "example@mail.com", isDark),
        _buildInputField("كلمة المرور", Icons.lock_outline, "********", isDark, isPassword: true),
      ],
    );
  }

  // --- الخطوة الثانية: اختيار الدور ---
  Widget _buildStep2(bool isDark) {
    return Column(
      key: const ValueKey(2),
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            _roleCard(
              label: "سجل كعميل",
              icon: Icons.person_search_outlined,
              isSelected: role == "client",
              activeColor: Colors.black,
              onTap: () => setState(() => role = "client"),
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            _roleCard(
              label: "سجل كميكانيكي",
              icon: Icons.handyman_outlined,
              isSelected: role == "mechanic",
              activeColor: primaryColor,
              onTap: () => setState(() => role = "mechanic"),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          role == "client" 
              ? "ستتمكن من طلب خدمات الصيانة فوراً" 
              : "سنطلب منك بيانات ورشتك في الخطوة القادمة داخل التطبيق",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- ويدجت بطاقة اختيار الدور (Role Card) ---
  Widget _roleCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
              width: 2,
            ),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ويدجت حقل الإدخال ---
  Widget _buildInputField(String label, IconData icon, String hint, bool isDark, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF137FEC).withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            ),
            child: TextField(
              obscureText: isPassword,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                // في RTL، الـ prefixIcon يظهر جهة اليمين
                prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}