import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RescheduleModal extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onSuccess;

  const RescheduleModal({super.key, required this.booking, this.onSuccess});

  @override
  State<RescheduleModal> createState() => _RescheduleModalState();
}

class _RescheduleModalState extends State<RescheduleModal> {
  String newDate = "";
  String newSlotStart = "";
  String newSlotEnd = "";
  bool loading = false;

  final String baseUrl = "https://gearupapp.runasp.net/api";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // ================= INIT (زي useEffect) =================
  void _initData() {
    newDate = _formatDate(widget.booking["date"]);

    newSlotStart = _normalizeTime(
      widget.booking["slotStart"] ?? widget.booking["time"] ?? "",
    );

    newSlotEnd = _normalizeTime(widget.booking["slotEnd"] ?? "");
  }

  // ================= HELPERS =================
  String _formatDate(String date) {
    try {
      return DateTime.parse(date).toIso8601String().split("T")[0];
    } catch (_) {
      return date.split("T")[0];
    }
  }

  String _normalizeTime(String time) {
    if (time.isEmpty) return "";
    final clean = time.contains("T") ? time.split("T")[1] : time;
    return clean.split(".")[0].substring(0, 5);
  }

  String _toApiTime(String time) {
    return time.length == 5 ? "$time:00" : time;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  // ================= API =================
  Future<void> _handleReschedule() async {
    final bookingId = widget.booking["id"];

    if (newDate.isEmpty || newSlotStart.isEmpty || newSlotEnd.isEmpty) {
      _showMsg("من فضلك املي البيانات");
      return;
    }

    if (newSlotEnd.compareTo(newSlotStart) <= 0) {
      _showMsg("وقت النهاية لازم يكون بعد البداية");
      return;
    }

    try {
      setState(() => loading = true);

      final token = await _getToken();

      final res = await http.put(
        Uri.parse("$baseUrl/bookings/$bookingId/reschedule"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "*/*",
        },
        body: jsonEncode({
          "newDate": newDate,
          "newSlotStart": _toApiTime(newSlotStart),
          "newSlotEnd": _toApiTime(newSlotEnd),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSuccess?.call();
        _showMsg("تم تغيير الموعد بنجاح");
      } else {
        final data = jsonDecode(res.body);
        _showMsg(data["message"] ?? "خطأ أثناء التعديل");
      }
    } catch (e) {
      _showMsg("حدث خطأ");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.center)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final fieldColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : Colors.black;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: isDark
              ? Border.all(color: Colors.white10)
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            Text(
              "تغيير موعد",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 20),

            _buildField(
              label: "التاريخ",
              value: newDate,
              bg: fieldColor,
              textColor: textColor,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() {
                    newDate = picked.toIso8601String().split("T")[0];
                  });
                }
              },
            ),

            _buildField(
              label: "وقت البداية",
              value: newSlotStart,
              bg: fieldColor,
              textColor: textColor,
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null) {
                  setState(() {
                    newSlotStart =
                        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),

            _buildField(
              label: "وقت النهاية",
              value: newSlotEnd,
              bg: fieldColor,
              textColor: textColor,
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null) {
                  setState(() {
                    newSlotEnd =
                        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade200,
                      foregroundColor: textColor,
                    ),
                    child: const Text("إلغاء"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : _handleReschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                    ),
                    child: Text(
                      loading ? "جاري..." : "تغيير الموعد",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color bg,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(color: textColor)),
          const SizedBox(height: 5),
          InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                value.isEmpty ? "اختر..." : value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: value.isEmpty ? Colors.grey : textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
