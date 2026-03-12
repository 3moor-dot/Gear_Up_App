import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  // الحقول (نفس منطقPasswords state في React)
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // رؤية كلمة المرور
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // الحالات (Loading & Status)
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  final String _baseUrl = "https://gearupapp.runasp.net/api/auth/change-password";

  // دالة تغيير كلمة المرور (نفس منطق handleChangePassword)
  Future<void> _changePassword() async {
    setState(() {
      _statusMessage = null;
    });

    // 1. التحقق من تطابق كلمة المرور (Client-side validation)
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _statusMessage = "كلمة المرور الجديدة غير متطابقة";
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.post(
        Uri.parse(_baseUrl),
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _isSuccess = true;
          _statusMessage = data['message'] ?? "تم تغيير كلمة المرور بنجاح ✅";
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        
        // إعادة تحميل الصفحة بعد ثانية كما في كود React
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _fetchProfileAndRefresh();
        });
      } else {
        setState(() {
          _isSuccess = false;
          _statusMessage = data['message'] ?? "فشل التغيير، تأكد من كلمة المرور الحالية";
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = "حدث خطأ في الاتصال بالسيرفر";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fetchProfileAndRefresh() {
    // يمكنك إضافة منطق إعادة التوجيه هنا أو تحديث الـ State
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF137FEC);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.blue.withOpacity(0.1) : Colors.grey[200]!),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header (نفس تصميم React)
          _buildHeader(primaryBlue, isDark),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("بيانات كلمة المرور", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Status Message (Banner)
                if (_statusMessage != null) _buildStatusBanner(),

                // Fields
                _buildPasswordField(
                  label: "كلمة المرور الحالية",
                  controller: _currentPasswordController,
                  isVisible: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                  isDark: isDark,
                  primaryColor: primaryBlue,
                ),
                _buildPasswordField(
                  label: "كلمة المرور الجديدة",
                  controller: _newPasswordController,
                  isVisible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  isDark: isDark,
                  primaryColor: primaryBlue,
                ),
                _buildPasswordField(
                  label: "تأكيد كلمة المرور الجديدة",
                  controller: _confirmPasswordController,
                  isVisible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  isDark: isDark,
                  primaryColor: primaryBlue,
                ),

                const SizedBox(height: 10),

                // Info Note
                _buildInfoNote(isDark, primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.lock_person_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("إعدادات الأمان", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("تغيير كلمة المرور", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600])),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(
                  children: [
                    Icon(Icons.save_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text("حفظ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _isSuccess ? Colors.green : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_isSuccess ? Icons.check_circle_outline : Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_statusMessage!, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: !isVisible,
            textAlign: TextAlign.right,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "••••••••",
              prefixIcon: IconButton(
                icon: Icon(isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey, size: 20),
                onPressed: onToggle,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF131C2F) : Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        "ملاحظة: يفضل أن تحتوي كلمة المرور على 8 أحرف على الأقل، بما في ذلك أرقام ورموز خاصة.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}