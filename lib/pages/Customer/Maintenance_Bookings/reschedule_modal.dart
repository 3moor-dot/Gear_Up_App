import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RescheduleModal extends StatefulWidget {
  final Map<String, dynamic>? booking;
  final VoidCallback? onSuccess;

  const RescheduleModal({
    super.key,
    required this.booking,
    this.onSuccess,
  });

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
    _fillData();
  }

  @override
  void didUpdateWidget(covariant RescheduleModal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.booking?["id"] != widget.booking?["id"]) {
      _fillData();
    }
  }

  void _fillData() {
    final booking = widget.booking;

    if (booking == null) return;

    setState(() {
      newDate = _formatDateForInput(booking["date"] ?? "");

      newSlotStart = _normalizeTimeForInput(
        booking["slotStart"] ?? booking["time"] ?? "",
      );

      newSlotEnd = _normalizeTimeForInput(
        booking["slotEnd"] ?? "",
      );
    });
  }

  String _formatDateForInput(String date) {
    if (date.isEmpty) return "";

    try {
      return DateTime.parse(date)
          .toIso8601String()
          .split("T")[0];
    } catch (_) {
      return date.split("T")[0];
    }
  }

  String _normalizeTimeForInput(String time) {
    if (time.isEmpty) return "";

    final pureTime =
        time.contains("T") ? time.split("T")[1] : time;

    final cleaned = pureTime.split(".")[0];

    final hhmmss =
        RegExp(r'^\d{2}:\d{2}:\d{2}$');

    final hhmm =
        RegExp(r'^\d{2}:\d{2}$');

    if (hhmmss.hasMatch(cleaned)) {
      return cleaned.substring(0, 5);
    }

    if (hhmm.hasMatch(cleaned)) {
      return cleaned;
    }

    return "";
  }

  String _toApiTimeFormat(String time) {
    if (time.isEmpty) return "";
    return time.length == 5 ? "$time:00" : time;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Future<void> _handleReschedule() async {
    final bookingId = widget.booking?["id"];

    if (bookingId == null) {
      _showError("معرف الحجز غير موجود");
      return;
    }

    if (newDate.isEmpty ||
        newSlotStart.isEmpty ||
        newSlotEnd.isEmpty) {
      _showWarning(
        "من فضلك املي التاريخ ووقت البداية ووقت النهاية",
      );
      return;
    }

    if (newSlotEnd.compareTo(newSlotStart) <= 0) {
      _showWarning(
        "وقت النهاية لازم يكون بعد وقت البداية",
      );
      return;
    }

    try {
      setState(() => loading = true);

      final token = await _getToken();

      final response = await http.put(
        Uri.parse(
          "$baseUrl/bookings/$bookingId/reschedule",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "*/*",
        },
        body: jsonEncode({
          "newDate": newDate,
          "newSlotStart":
              _toApiTimeFormat(newSlotStart),
          "newSlotEnd":
              _toApiTimeFormat(newSlotEnd),
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        if (!mounted) return;

        _showSuccess(
          "تم تغيير موعد الحجز بنجاح",
        );

        widget.onSuccess?.call();

        Navigator.pop(context);
        return;
      }

      String message = "حدث خطأ أثناء تغيير الموعد";

      try {
        final data = jsonDecode(response.body);

        message =
            data["title"] ??
            data["message"] ??
            data["errors"]?["newSlotStart"]?[0] ??
            data["errors"]?["newSlotEnd"]?[0] ??
            data["errors"]?["newDate"]?[0] ??
            message;
      } catch (_) {}

      _showError(message);
    } catch (e) {
      _showError(
        "حدث خطأ أثناء تغيير الموعد",
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showWarning(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        content: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: newDate.isNotEmpty
          ? DateTime.parse(newDate)
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        newDate =
            picked.toIso8601String().split("T")[0];
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        newSlotStart =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        newSlotEnd =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 700,
        ),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(40),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: () =>
                    Navigator.pop(context),
              ),
            ),

            Text(
              "تغيير موعد",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    "التاريخ الجديد",
                    newDate,
                    Icons.calendar_month,
                    _pickDate,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: _buildPickerField(
                    "وقت البداية",
                    newSlotStart,
                    Icons.access_time,
                    _pickStartTime,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: _buildPickerField(
                    "وقت النهاية",
                    newSlotEnd,
                    Icons.access_time,
                    _pickEndTime,
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () =>
                            Navigator.pop(
                              context,
                            ),
                    style:
                        ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      "إلغاء",
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : _handleReschedule,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF137FEC,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      loading
                          ? "جاري تغيير الموعد..."
                          : "تغيير الموعد",
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
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

  Widget _buildPickerField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF3F4F6),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDark
                      ? Colors.white70
                      : Colors.black54,
                ),
                const Spacer(),
                Text(
                  value.isEmpty
                      ? "اختر..."
                      : value,
                  style: TextStyle(
                    color: value.isEmpty
                        ? Colors.grey
                        : (isDark
                              ? Colors.white
                              : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}