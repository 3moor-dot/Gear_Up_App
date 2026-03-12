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
  // ======= الحالات (States) =======
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

  // ======= جلب البيانات من الـ API =======
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

  // ======= العمليات (Actions) =======
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل تنفيذ العملية: $e")));
    }
  }

  Future<void> _deleteReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken");
    try {
      await http.delete(
        Uri.parse("https://gearupapp.runasp.net/api/Reminder/$id/delete"),
        headers: {"Authorization": "Bearer $token"},
      );
      _fetchReminders();
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  // ======= المصفاة (Filtering) =======
  List<dynamic> get _filteredReminders {
    if (_activeTab == 0)
      return _reminders.where((r) => r['status'] != "Completed").toList();
    if (_activeTab == 1)
      return _reminders.where((r) => r['status'] == "Active").toList();
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
                        const Center(child: Text("لا توجد تذكيرات نشطة")),

                      const SizedBox(height: 30),
                      _buildCompletedHistory(isDark),
                      const SizedBox(height: 25),
                      _buildCustomReminderPromo(primaryColor),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
        if (_selectedCar != null) _buildCarPicker(primaryColor),
      ],
    );
  }

  Widget _buildCarPicker(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<Map<String, dynamic>>(
        value: _selectedCar,
        dropdownColor: primaryColor,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        items: _cars
            .map(
              (c) => DropdownMenuItem<Map<String, dynamic>>(
                value: c,
                child: Text(
                  "${c['brand']} ${c['model']}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          setState(() => _selectedCar = v);
          _fetchReminders();
        },
      ),
    );
  }

  Widget _buildReminderCard(
    Map<String, dynamic> r,
    Color primaryColor,
    bool isDark,
  ) {
    bool isActive = r['status'] == "Active";
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF137FEC).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isActive
              ? Colors.blue.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'yyyy/MM/dd',
                      ).format(DateTime.parse(r['startDate'])),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text("حذف"),
                    onTap: () => _deleteReminder(r['id']),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _handleAction(r['id'], isActive ? "pause" : "activate"),
                  style: ElevatedButton.styleFrom(
                    // تعديل الخلفية لتكون أغمق قليلاً في اللايت مود لزيادة التباين
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200],
                    // تعديل لون النص والأيقونة ليكون واضحاً
                    foregroundColor: isActive
                        ? (isDark
                              ? Colors.orangeAccent
                              : const Color(
                                  0xFFE65100,
                                )) // برتقالي داكن للايت مود
                        : Colors.green[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isActive ? "إيقاف مؤقت" : "تنشيط",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction(r['id'], "complete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blueAccent : Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "إتمام",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "تاريخ مكتمل",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(Icons.history, color: Colors.green),
            ],
          ),
          const Divider(height: 30),
          ..._completedReminders.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 10),
                  Text(r['name'], style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text(
                    DateFormat('MM/dd').format(DateTime.parse(r['startDate'])),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- دوال مساعدة للواجهة ---
  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
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
        Row(
          children: List.generate(
            tabs.length,
            (index) => GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _activeTab == index
                      ? primaryColor
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
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
        FloatingActionButton.small(
          backgroundColor: primaryColor,
          onPressed: () =>
              CreateReminderModal.show(context, onSuccess: _fetchReminders),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCustomReminderPromo(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_alert_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          const Text(
            "تذكيرات مخصصة",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Text(
            "اضبط تذكيرات لتجديد التأمين أو غسيل السيارة",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                CreateReminderModal.show(context, onSuccess: _fetchReminders),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
            ),
            child: const Text("إنشاء تذكير جديد"),
          ),
        ],
      ),
    );
  }
}
