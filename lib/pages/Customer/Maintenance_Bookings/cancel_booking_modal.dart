import 'dart:ui';
import 'package:flutter/material.dart';

class CancelBookingDialog extends StatelessWidget {
  const CancelBookingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      // تأثير البلور الخلفي (Blur)
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            // لون مستوحى من كود الـ React (Dark blue with opacity)
            color: const Color(0xFF137FEC).withOpacity(0.4),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // زر الإغلاق
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                ),
              ),

              const Text(
                "إلغاء الطلب",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                "سبب إلغاء الطلب",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // حقل إدخال النص (Textarea)
              TextField(
                maxLines: 5,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "اكتب سبب الإلغاء هنا...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F1323).withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // زر الإلغاء النهائي
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // إظهار رسالة تأكيد
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("تم إلغاء الطلب بنجاح", textAlign: TextAlign.center),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      "إلغاء الطلب الآن",
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}