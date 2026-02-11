import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // الحالات (States)
  String role = "client"; // client or mechanic
  int step = 1; // 1 or 2

  final primaryColor = const Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
       // AppBar بسيط للعودة للخلف
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, 
                color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1323), const Color(0xFF101922)]
                : [Colors.white, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500), // ليشبه max-w-xl
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step == 1 ? "ابدأ بإدخال بياناتك الأساسية" : "اختر نوع الحساب لإكمال التسجيل",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // FORM STEPS WITH ANIMATION
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: step == 1
                          ? _buildStep1(isDark)
                          : _buildStep2(isDark),
                    ),

                    const SizedBox(height: 30),

                    // NAVIGATION BUTTONS
                    Row(
                      children: [
                        if (step == 2) ...[
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => setState(() => step = 1),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade400),
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
                            onPressed: () {
                              if (step == 1) {
                                setState(() => step = 2);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("تم التسجيل بنجاح!")));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                            ),
                            child: Text(
                              step == 1 ? "التالي" : "إنهاء التسجيل",
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // LOGIN LINK
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Text.rich(
                        TextSpan(
                          text: "هل لديك حساب بالفعل؟ ",
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
    );
  }

  // --- الخطوة الأولى: البيانات الأساسية ---
  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey(1),
      children: [
        Row(
          children: [
            Expanded(child: _buildInputField("الاسم الأول", Icons.person, "الاسم الأول", isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField("اسم العائلة", Icons.person, "العائلة", isDark)),
          ],
        ),
        _buildInputField("رقم الهاتف", Icons.phone, "أدخل رقم الهاتف", isDark),
        _buildInputField("البريد الإلكتروني", Icons.email, "أدخل بريدك الإلكتروني", isDark),
        _buildInputField("كلمة المرور", Icons.lock, "أدخل كلمة المرور", isDark, isPassword: true),
        _buildInputField("تأكيد كلمة المرور", Icons.lock, "أعد إدخال كلمة المرور", isDark, isPassword: true),
      ],
    );
  }

  // --- الخطوة الثانية: اختيار الدور وبيانات الميكانيكي ---
  Widget _buildStep2(bool isDark) {
    return Column(
      key: const ValueKey(2),
      children: [
        // ROLE SWITCH
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roleButton(
              label: "عميل",
              icon: Icons.person_outline,
              isSelected: role == "client",
              activeColor: Colors.black,
              onTap: () => setState(() => role = "client"),
            ),
            const SizedBox(width: 12),
            _roleButton(
              label: "ميكانيكي",
              icon: Icons.build,
              isSelected: role == "mechanic",
              activeColor: primaryColor,
              onTap: () => setState(() => role = "mechanic"),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // بيانات متغيرة بناءً على الدور
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: role == "mechanic"
              ? Container(
                  key: const ValueKey("mech"),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("بيانات الورشة والعمل:", 
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 16),
                      _buildInputField("موقع الورشة", Icons.location_on, "أدخل موقع الورشة", isDark),
                      _buildInputField("التخصص الرئيسي", Icons.handyman, "ميكانيكي / كهربائي", isDark),
                      _buildInputField("التخصص الفرعي", Icons.star, "ألماني / كوري / ياباني", isDark),
                      _buildInputField("إمكانية الزيارة الميدانية", Icons.check_circle, "نعم / لا", isDark),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey("cli"),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Text(
                    "سيتم إنشاء حسابك كعميل، يمكنك إضافة بيانات سيارتك لاحقاً من لوحة التحكم.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
        ),
      ],
    );
  }

  // --- ويدجت زر اختيار الدور ---
  Widget _roleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 10)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF137FEC).withOpacity(0.1) : const Color(0xFFD6E9FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              obscureText: isPassword,
              textAlign: TextAlign.right,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(icon, color: isDark ? Colors.blueGrey : Colors.blueGrey.shade300, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}