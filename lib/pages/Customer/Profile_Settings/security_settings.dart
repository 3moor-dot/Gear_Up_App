import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettingsTab extends StatefulWidget {
  const SecuritySettingsTab({super.key});

  @override
  State<SecuritySettingsTab> createState() => _SecuritySettingsTabState();
}

class _SecuritySettingsTabState extends State<SecuritySettingsTab> {
  // وحدات التحكم في النصوص
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // حالات الرؤية (العين)
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // حالات النظام
  bool _loading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  final String baseUrl = "https://gearupapp.runasp.net/api/auth/change-password";
  final primaryColor = const Color(0xFF137FEC);

  // وظيفة تغيير كلمة المرور (Logic)
  Future<void> _handleChangePassword() async {
    setState(() {
      _statusMessage = null;
    });

    // التحقق من تطابق كلمة المرور الجديدة
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _statusMessage = "كلمة المرور الجديدة غير متطابقة";
        _isSuccess = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "currentPassword": _currentPasswordController.text,
          "newPassword": _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isSuccess = true;
          _statusMessage = data['message'] ?? "تم تغيير كلمة المرور بنجاح";
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage =
              data['message'] ?? "فشل التغيير، تأكد من كلمة المرور الحالية";
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = "حدث خطأ في الاتصال بالسيرفر";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: primaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الهيدر
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "كلمة المرور",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(),
            ),

            // رسالة الحالة (نجاح أو خطأ)
            if (_statusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

            // الحقول
            _buildPasswordField(
              label: "كلمة المرور الحالية",
              controller: _currentPasswordController,
              isObscure: !_showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              label: "كلمة المرور الجديدة",
              controller: _newPasswordController,
              isObscure: !_showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              label: "تأكيد كلمة المرور الجديدة",
              controller: _confirmPasswordController,
              isObscure: !_showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
            ),

            const SizedBox(height: 40),

            // زر الحفظ
            ElevatedButton(
              onPressed: _loading ? null : _handleChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "تأكيد التغيير",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.save, color: Colors.white),
                      ],
                    ),
            ),

            const SizedBox(height: 30),

            // ملاحظة أمنية
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Text(
                "ملاحظة أمنية: يفضل أن تحتوي كلمة المرور على 8 أحرف على الأقل، بما في ذلك أرقام ورموز خاصة لضمان حماية حسابك.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // جعل النص فوق الحقل يبدأ من اليمين
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          textAlign: TextAlign.right, // الكتابة تبدأ من اليمين
          decoration: InputDecoration(
            hintText: "••••••••",
            filled: true,
            fillColor: primaryColor.withOpacity(0.05),

            // تغيير مكان العين إلى اليسار عبر استخدام suffixIcon
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: isObscure ? Colors.grey : primaryColor,
              ),
              onPressed: onToggle,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
