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
  Future<void> _handleAction(int id, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");
    try {
      final res = await http.post(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder/$id/$action"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) _fetchReminders();
    } catch (e) {
      _showSnackBar("فشل تنفيذ العملية");
    }
  }

  Future<void> _deleteReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");

    // أضفنا setState بسيط لإظهار أن العملية بدأت (اختياري)
    try {
      final res = await http.delete(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder/$id/delete"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json", // تأكد من إضافة الهيدرز اللازمة
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        await _fetchReminders(); // ننتظر جلب البيانات الجديدة
        _showSnackBar("تم حذف التذكير بنجاح");
      } else {
        _showSnackBar("فشل الحذف: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      _showSnackBar("حدث خطأ أثناء الاتصال بالسيرفر");
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

  void _showConfirmDelete(int id) {
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
                            Navigator.of(
                              dialogContext,
                            ).pop(); // نغلق المودال أولاً باستخدام الـ context الخاص به
                            _deleteReminder(id); // ثم ننفذ عملية الحذف
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

  // ======= بطاقة التذكير المحدثة =======
  Widget _buildReminderCard(
    Map<String, dynamic> r,
    Color primaryColor,
    bool isDark,
  ) {
    bool isActive = r['status'] == "Active";
    final dateTime = DateTime.parse(r['startDate']);
    final dateStr = DateFormat('yyyy/MM/dd').format(dateTime);
    final timeStr = DateFormat.jm('ar_EG').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A233A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? Colors.blue.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. أيقونة الصيانة أصبحت الآن في أقصى اليسار
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.blue : Colors.orange).withOpacity(
                    0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: isActive ? Colors.blue : Colors.orange,
                  size: 26,
                ),
              ),

              const SizedBox(width: 15),

              // 2. النصوص في المنتصف ومحاذاتها لليمين لتناسب مكانها الجديد
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليمين
                  children: [
                    Text(
                      r['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$dateStr  $timeStr",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // داخل _buildReminderCard ابحث عن PopupMenuButton
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                onSelected: (val) {
                  if (val == 'delete') {
                    _showConfirmDelete(r['id']); // تم التغيير هنا
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text("حذف", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // الأزرار تبقى كما هي
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _handleAction(r['id'], isActive ? "pause" : "activate"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    isActive ? "إيقاف مؤقت" : "تنشيط",
                    style: TextStyle(
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction(r['id'], "complete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text(
                    "إتمام",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
                  final timeStr = DateFormat.jm('ar_EG').format(dateTime);

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
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
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
          onPressed: () => CreateReminderModal.show(context, onSuccess: _fetchReminders),
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
