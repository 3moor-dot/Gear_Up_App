import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../components/Customer/customer_sidebar.dart';
import '../../../components/Customer/customer_header.dart';
import './create_reminder_modal.dart';

class MaintenanceRemindersPage extends StatefulWidget {
  const MaintenanceRemindersPage({super.key});

  @override
  State<MaintenanceRemindersPage> createState() =>
      _MaintenanceRemindersPageState();
}

class _MaintenanceRemindersPageState extends State<MaintenanceRemindersPage> {
  int _activeTab = 0; // 0: الكل, 1: نشط, 2: متوقف
  List<dynamic> _cars = [];
  Map<String, dynamic>? _selectedCar;
  List<dynamic> _reminders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  // ======= جلب البيانات =======
  Future<void> _fetchCars() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");
    try {
      final res = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/customers/cars"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _cars = data['cars'] ?? [];
          if (_cars.isNotEmpty) {
            _selectedCar = _cars[0];
            _fetchReminders();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching cars: $e");
    }
  }

  String getFrequencyLabel(Map<String, dynamic> r) {
    final rawType = (r['frequencyType'] ?? "").toString().toLowerCase();
    final val = int.tryParse(r['intervalValue']?.toString() ?? "0") ?? 0;
    final unitKey = (r['intervalUnit'] ?? "0").toString();

    switch (rawType) {
      case "0":
      case "once":
        return "مرة واحدة";

      case "1":
      case "daily":
        return "يومي";

      case "2":
      case "weekly":
        return "أسبوعي";

      case "3":
      case "monthly":
        return "شهري";

      case "4":
      case "yearly":
        return "سنوي";

      case "5":
      case "custom":
      case "custominterval":
        Map<String, String> unitMap = {
          "0": "أيام",
          "1": "أسابيع",
          "2": "شهور",
          "3": "سنوات",
        };

        return "كل $val ${unitMap[unitKey] ?? "أيام"}";

      default:
        return "غير معروف";
    }
  }

  Future<void> _fetchReminders() async {
    if (_selectedCar == null) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    try {
      final res = await http.get(
        Uri.parse(
          "https://gearupapp.runasp.net/api/Reminder/car/${_selectedCar!['id']}",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        setState(() => _reminders = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint("Error fetching reminders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ======= العمليات (تطابق منطق React) =======
  Future<bool> _handleAction(String id, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    try {
      final res = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder/$id/$action"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({}),
      );

      debugPrint("ACTION STATUS: ${res.statusCode}");
      debugPrint("ACTION BODY: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // العملية نجحت → حدث الحالة أولًا
        return true;
      } else {
        _showSnackBar("فشل العملية: ${res.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("ACTION ERROR: $e");
      _showSnackBar("خطأ في الاتصال بالسيرفر");
      return false;
    }
  }

  Future<void> _deleteReminder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    try {
      final res = await http.delete(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder/$id/delete"),
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("DELETE STATUS: ${res.statusCode}");
      debugPrint("DELETE BODY: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          _reminders.removeWhere((r) => r['id'].toString() == id);
        });

        _showSnackBar("تم حذف التذكير بنجاح");
      } else {
        _showSnackBar("فشل الحذف");
      }
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
      _showSnackBar("خطأ في الاتصال بالسيرفر");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center), // توسيط النص
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 250, // جعلها صغيرة مثل الـ Toast
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConfirmDelete(String id) {
    // نستخدم Future.delayed بسيط للتأكد من أن القائمة المنبثقة (PopupMenu) أغلقت تماماً قبل فتح المودال
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          // نستخدم dialogContext هنا
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: isDark ? const Color(0xFF1A233A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "!",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "تأكيد الحذف",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "هل أنت متأكد من حذف هذا التذكير؟ لا يمكن التراجع عن هذا الإجراء.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(
                            "إلغاء",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.red[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();

                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                _deleteReminder(id);
                              },
                            );
                          },
                          child: const Text(
                            "نعم، احذفه",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
        },
      );
    });
  }

  // ======= الفلترة =======
  List<dynamic> get _filteredReminders {
    if (_activeTab == 0) {
      return _reminders.where((r) => r['status'] != "Completed").toList();
    }
    if (_activeTab == 1) {
      return _reminders.where((r) => r['status'] == "Active").toList();
    }
    return _reminders.where((r) => r['status'] == "Paused").toList();
  }

  List<dynamic> get _completedReminders =>
      _reminders.where((r) => r['status'] == "Completed").toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: '/customer/reminders'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchReminders,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildTopHeader(primaryColor, isDark),
                    const SizedBox(height: 25),
                    _buildTabsAndAddAction(primaryColor, isDark),
                    const SizedBox(height: 25),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      _buildSectionTitle("المهام القادمة", primaryColor),
                      const SizedBox(height: 15),
                      ..._filteredReminders.map(
                        (r) => _buildReminderCard(r, primaryColor, isDark),
                      ),
                      if (_filteredReminders.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("لا توجد تذكيرات حالياً"),
                          ),
                        ),
                      const SizedBox(height: 30),
                      _buildCompletedHistory(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(Color primaryColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // النصوص أصبحت في اليسار
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "تذكيرات الصيانة",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "إدارة مهام سيارتك",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        // مختار السيارة أصبح في اليمين
        if (_selectedCar != null) _buildCarPicker(primaryColor),
      ],
    );
  }

  Widget _buildCarPicker(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedCar,
          icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
          items: _cars
              .map(
                (c) => DropdownMenuItem<Map<String, dynamic>>(
                  value: c,
                  child: Text(
                    "${c['brand']} ${c['model']}",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _selectedCar = v);
            _fetchReminders();
          },
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    Map<String, dynamic> r,
    Color primaryColor,
    bool isDark,
  ) {
    bool isActive = r['status'] == "Active";

    final dateTime = DateTime.parse(r['startDate']);
    final dateStr = DateFormat('yyyy/MM/dd').format(dateTime);
    String timeStr = "غير محدد";
    final isOnce =
        r['frequencyType'].toString().toLowerCase() == "0" ||
        r['frequencyType'].toString().toLowerCase() == "once";

    if (r['preferredNotificationTime'] != null &&
        r['preferredNotificationTime'].toString().isNotEmpty) {
      try {
        final parts = r['preferredNotificationTime'].split(":");
        final now = DateTime.now();

        final date = DateTime.utc(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        ).toLocal();

        timeStr = DateFormat.jm('ar_EG').format(date);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== الجزء العلوي =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// أيقونة الصيانة
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.build, color: Colors.blue, size: 28),
              ),

              const SizedBox(width: 14),

              /// النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Badge الحالة
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? "نشط" : "متوقف",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),

                    /// اسم التذكير
                    Text(
                      r['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    if (r['description'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${r['description']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// ===== معلومات التذكير =====
          Container(
            padding: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.sync, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      getFrequencyLabel(r),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// ===== الأزرار =====
          Row(
            children: [
              /// إتمام
              if (!isOnce && r['status'] != "Completed")
                _actionButton(
                  icon: Icons.check,
                  label: "إتمام",
                  color: Colors.green,
                  onTap: () async {
                    bool success = await _handleAction(
                      r['id'].toString(),
                      "complete",
                    );

                    if (success) {
                      setState(() => r['status'] = "Completed");
                    }
                  },
                ),

              if (!isOnce) const SizedBox(width: 8),

              /// إيقاف / تشغيل
              if (!isOnce && r['status'] == "Active")
                _actionButton(
                  icon: Icons.pause,
                  label: "إيقاف",
                  color: Colors.orange,
                  onTap: () async {
                    bool success = await _handleAction(r['id'], "pause");

                    if (success) {
                      setState(() => r['status'] = "Paused");
                    }
                  },
                )
              else if (!isOnce && r['status'] == "Paused")
                _actionButton(
                  icon: Icons.play_arrow,
                  label: "تنشيط",
                  color: Colors.orange,
                  onTap: () async {
                    bool success = await _handleAction(r['id'], "activate");

                    if (success) {
                      setState(() => r['status'] = "Active");
                    }
                  },
                ),

              const SizedBox(width: 8),

              /// حذف
              _actionButton(
                icon: Icons.delete,
                label: "حذف",
                color: Colors.red,
                onTap: () => _showConfirmDelete(r['id'].toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// زر الأكشن
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedHistory(bool isDark) {
    if (_completedReminders.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("السجل المكتمل", Colors.green),
        const SizedBox(height: 15),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A233A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                children: _completedReminders.map((r) {
                  final dateTime = DateTime.parse(r['startDate']);
                  final dateStr = DateFormat('MM/dd').format(dateTime);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          r['name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // عرض التاريخ والوقت
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // زر الحذف (✕) ليعمل مثل React تماماً
                        GestureDetector(
                          onTap: () => _showConfirmDelete(
                            r['id'],
                          ), // استدعاء مودال التأكيد
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // محاذاة لليسار
      children: [
        // الخط أصبح في اليسار أولاً
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTabsAndAddAction(Color primaryColor, bool isDark) {
    List<String> tabs = ["الجميع", "نشط", "متوقف"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // التبويبات في اليسار
        Row(
          children: List.generate(
            tabs.length,
            (index) => GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _activeTab == index
                      ? primaryColor
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: _activeTab == index ? Colors.white : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),

        // زر الإضافة الجديد مع النص في اليمين
        ElevatedButton.icon(
          onPressed: () =>
              CreateReminderModal.show(context, onSuccess: _fetchReminders),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text(
            "إضافة تذكير",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
