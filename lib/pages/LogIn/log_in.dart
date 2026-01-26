import 'package:flutter/material.dart';
import 'package:gear_up_app/pages/Registration/register.dart';
import 'package:gear_up_app/pages/Forgot_Password/forgot_password.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
      // backgroundColor يتغير تلقائياً بناءً على الـ ThemeData في الـ MaterialApp
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // IMAGE SECTION (Car AI)
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/car.png',
                        width: double
                            .infinity, 
                        height:
                            200,
                        fit: BoxFit
                            .cover, 
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 180,
                          color: const Color(0xFF137FEC).withOpacity(0.1),
                          child: const Icon(
                            Icons.directions_car,
                            size: 100,
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "العناية الذكية بالسيارة، بشكل مبسط",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "مساعدك المدعم بالذكاء الاصطناعي لصيانة السيارة وتحسين أدائها.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // HEADER TEXT
              const Text(
                "مرحباً بعودتك 👋",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "تسجيل الدخول إلى حسابك",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 40),

              // EMAIL / PHONE INPUT
              _buildLabel("البريد الإلكتروني أو رقم الهاتف", primaryColor),
              _buildTextField(
                hint: "ادخل البريد الإلكتروني أو رقم الهاتف",
                icon: Icons.phone_android,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // PASSWORD INPUT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      "هل نسيت كلمة السر؟",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildLabel("كلمة المرور", null),
                ],
              ),
              _buildTextField(
                hint: "ادخل كلمة المرور",
                icon: Icons.lock_outline,
                isDark: isDark,
                isPassword: true,
              ),

              const SizedBox(height: 32),

              // LOGIN BUTTON
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "تسجيل الدخول",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 24),

              // REGISTER LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ), // تأكد أن اسم الكلاس هو LoginPage
                            );
                          },
                    child: const Text(
                      "قم بالتسجيل",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text("  ليس لديك حساب؟"),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers Widgets ---

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
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.emailAddress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF137FEC).withOpacity(0.1)
            : const Color(0xFF8EC1F5).withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        obscureText: isPassword,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
