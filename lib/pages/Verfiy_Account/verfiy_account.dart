import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  int _timerValue = 60;
  Timer? _timer;
  String _error = "";

  // الالتزام بـ 5 خانات كما في كود React
  final int _otpLength = 5;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    _controllers = List.generate(_otpLength, (index) => TextEditingController());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerValue = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue > 0) {
        setState(() => _timerValue--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // منطق التحقق (نفس منطق handleVerify في React)
  Future<void> _handleVerify() async {
    String token = _controllers.map((e) => e.text).join("");

    if (token.length < _otpLength) {
      setState(() => _error = "يرجى إدخال الرمز كاملاً");
      return;
    }

    setState(() => _error = "");

    // حفظ التوكين في الجهاز للمرحلة القادمة (reset-password)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("reset_token", token);

    if (mounted) {
      // الانتقال لصفحة تعيين كلمة المرور الجديدة
      Navigator.pushNamed(context, '/reset-password');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) node.dispose();
    for (var controller in _controllers) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF137FEC).withOpacity(0.05) : const Color(0xFFE8F3FF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Text(
                    "التحقق من حسابك",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "لضمان سلامتك، يرجى إدخال الرمز المكون من 5 أرقام \nالذي أرسلناه إلى عنوان بريدك الإلكتروني للمتابعة.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.6, fontSize: 14),
                  ),

                  const SizedBox(height: 32),

                  // OTP Input Fields (LTR)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_otpLength, (index) => _buildOtpBox(index, isDark, primaryColor)),
                    ),
                  ),

                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),

                  const SizedBox(height: 32),

                  // Verify Button
                  ElevatedButton(
                    onPressed: _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("التحقق من الحساب", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                  const SizedBox(height: 24),

                  // Resend Timer Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text("لم تستلم الرمز؟ ", style: TextStyle(fontSize: 13)),
                          GestureDetector(
                            onTap: _timerValue == 0 ? () => setState(() => _startTimer()) : null,
                            child: Opacity(
                              opacity: _timerValue > 0 ? 0.5 : 1.0,
                              child: Text(
                                "أعد الإرسال",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: _timerValue == 0 ? TextDecoration.underline : TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatTime(_timerValue),
                        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 15),
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

  Widget _buildOtpBox(int index, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 50,
      height: 60,
      child: RawKeyboardListener(
        focusNode: FocusNode(), // FocusNode داخلي للتعامل مع الـ Backspace
        onKey: (event) {
          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          onChanged: (value) {
            if (value.isNotEmpty && index < _otpLength - 1) {
              _focusNodes[index + 1].requestFocus();
            }
          },
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            fillColor: isDark ? Colors.grey[700] : Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
          ),
        ),
      ),
    );
  }
}