import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CancelBookingModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String? bookingId;
  final VoidCallback? onSuccess;

  const CancelBookingModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.bookingId,
    this.onSuccess,
  });

  @override
  State<CancelBookingModal> createState() => _CancelBookingModalState();
}

class _CancelBookingModalState extends State<CancelBookingModal> {
  bool loading = false;
  final String baseUrl = "https://gearupapp.runasp.net/api";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Future<void> handleCancel() async {
    final bookingId = widget.bookingId;

    if (bookingId == null || bookingId.isEmpty) {
      showMsg("معرف الحجز غير موجود");
      return;
    }

    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        showMsg("انتهت الجلسة، سجل دخول تاني");
        return;
      }

      setState(() => loading = true);

      await http.post(
        Uri.parse("$baseUrl/bookings/$bookingId/cancel"),
        headers: {"Authorization": "Bearer $token", "Accept": "*/*"},
      );

      if (!mounted) return;

      showMsg("تم إلغاء الحجز بنجاح");

      widget.onSuccess?.call();
      widget.onClose();
    } catch (e) {
      showMsg("فشل إلغاء الحجز");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey;

    return Stack(
      children: [
        /// الخلفية
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),
        ),

        /// modal
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /// close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, color: subTextColor),
                  ),
                ),

                const SizedBox(height: 5),

                /// title
                Text(
                  "إلغاء الحجز",
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                /// subtitle
                Text(
                  "هل أنت متأكد أنك تريد إلغاء هذا الحجز؟",
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 14,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 25),

                /// warning box (UX مهم)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withOpacity(0.08)
                        : Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "لن يمكنك استعادة الحجز بعد الإلغاء",
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.red.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// buttons
                Row(
                  children: [
                    /// cancel
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF111827)
                              : Colors.grey.shade200,
                          foregroundColor: textColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "تراجع",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// delete
                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading ? null : handleCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "إلغاء الحجز",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
