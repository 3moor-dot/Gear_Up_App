import 'package:flutter/material.dart';
import 'package:gear_up_app/pages/LogIn/log_in.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // الحالات (States)
  String role = "client"; // client or mechanic
  int step = 1; // 1 or 2

  // متحكمات النصوص (Controllers)
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                const Text(
                  "تحكم في صيانة سيارتك باستخدام الرؤى المدعومة بالذكاء الاصطناعي",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                
                const SizedBox(height: 30),

                // ROLE SWITCH (MECHANIC / CLIENT)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _roleButton(
                      label: "ميكانيكي",
                      icon: Icons.build,
                      isSelected: role == "mechanic",
                      activeColor: primaryColor,
                      onTap: () => setState(() => role = "mechanic"),
                    ),
                    const SizedBox(width: 12),
                    _roleButton(
                      label: "عميل",
                      icon: Icons.person,
                      isSelected: role == "client",
                      activeColor: Colors.black,
                      onTap: () => setState(() => role = "client"),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // FORM STEPS WITH ANIMATION
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: step == 1 
                    ? _buildStep1(isDark) 
                    : _buildStep2(isDark, role),
                ),

                const SizedBox(height: 40),

                // MAIN BUTTON
                ElevatedButton(
                  onPressed: () {
                    if (step == 1) {
                      setState(() => step = 2);
                    } else {
                      // Logic لإنهاء التسجيل
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم التسجيل بنجاح!"))
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    step == 1 ? "التالي" : "إنهاء",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                // LOGIN LINK
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  ),
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
    );
  }

  // --- Widgets ---

  Widget _roleButton({
    required String label, 
    required IconData icon, 
    required bool isSelected, 
    required Color activeColor,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.scale(
        scale: isSelected ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
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

  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey(1),
      children: [
        _buildInputField("الاسم بالكامل", Icons.person, "أدخل الاسم بالكامل", isDark),
        _buildInputField("رقم الهاتف", Icons.phone, "أدخل رقم الهاتف", isDark),
        _buildInputField("البريد الإلكتروني", Icons.email, "أدخل بريدك الإلكتروني", isDark),
        _buildInputField("كلمة المرور", Icons.lock, "أدخل كلمة المرور", isDark, isPassword: true),
      ],
    );
  }

  Widget _buildStep2(bool isDark, String role) {
    return Column(
      key: const ValueKey(2),
      children: role == "client" 
        ? [
            _buildInputField("ماركة السيارة", Icons.directions_car, "أدخل ماركة السيارة", isDark),
            _buildInputField("طراز السيارة", Icons.model_training, "أدخل طراز السيارة", isDark),
            _buildInputField("سنة الصنع", Icons.calendar_today, "أدخل سنة التصنيع", isDark),
          ]
        : [
            _buildInputField("موقع الورشة", Icons.location_on, "أدخل موقع الورشة", isDark),
            _buildInputField("التخصص الرئيسي", Icons.handyman, "ميكانيكي / كهربائي", isDark),
            _buildInputField("التخصص الفرعي", Icons.star, "ألماني / كوري / ياباني", isDark),
          ],
    );
  }

  Widget _buildInputField(String label, IconData icon, String hint, bool isDark, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF137FEC).withOpacity(0.1) : const Color(0xFFD6E9FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              obscureText: isPassword,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: isDark ? Colors.grey : Colors.blueGrey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}