import 'package:flutter/material.dart';
// تأكد من صحة مسارات الملفات لديك
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';

class MachineDashboard extends StatelessWidget {
  const MachineDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isLargeScreen = MediaQuery.of(context).size.width > 1024;
    final Color bgColor = isDark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB);
    final Color cardColor = isDark ? const Color(0xFF0D1629) : Colors.white;
    final Color primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: bgColor,
      endDrawer: !isLargeScreen 
          ? const MachineDrawer(currentRoute: '/mechanic/dashboard') 
          : null,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              // 2. استخدام MachineDrawer كعنصر ثابت للشاشات الكبيرة (Sidebar)
              if (isLargeScreen)
                const SizedBox(
                  width: 280,
                  child: MachineDrawer(currentRoute: '/mechanic/dashboard'),
                ),
              
              Expanded(
                child: Column(
                  children: [
                    // 3. استدعاء الهيدر الجديد الذي صممناه
                    const MachineHeader(),
                    
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // الإحصائيات
                          _buildStatsSection(isDark, cardColor),
                          
                          const SizedBox(height: 24),
                          
                          // طلبات الحجز الجديدة
                          _buildSectionTitle("طلبات الحجز الجديدة", isDark),
                          const SizedBox(height: 12),
                          _buildBookingsList(isDark, cardColor, primaryColor),
                          
                          const SizedBox(height: 24),
                          
                          // المواعيد والمراجعات
                          if (isLargeScreen)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildAppointmentsSection(isDark, cardColor, primaryColor)),
                                const SizedBox(width: 20),
                                Expanded(child: _buildReviewsSection(isDark, cardColor)),
                              ],
                            )
                          else ...[
                            _buildAppointmentsSection(isDark, cardColor, primaryColor),
                            const SizedBox(height: 24),
                            _buildReviewsSection(isDark, cardColor),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الهيلبرز (نفس المنطق السابق مع تحسينات بسيطة) ---

  Widget _buildStatsSection(bool isDark, Color cardColor) {
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;
      int crossAxisCount = width > 600 ? 3 : 1;
      
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: width > 600 ? 1.4 : 2.5,
        children: [
          _statCard("طلبات الحجز", "4", "+2 عن الأمس", Colors.green, isDark, cardColor),
          _statCard("مواعيد اليوم", "7", "+1 عن الأمس", Colors.blue, isDark, cardColor),
          _statCard("التقييم العام", "4.8", "0+ هذا الشهر", Colors.orange, isDark, cardColor),
        ],
      );
    });
  }

  Widget _statCard(String title, String value, String change, Color color, bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text(change, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBookingsList(bool isDark, Color cardColor, Color primaryColor) {
    return Column(
      children: List.generate(2, (index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: primaryColor)
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("أليس مارتن", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("تويوتا كامري - تغيير زيت", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text("2:00 PM", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _actionButton("قبول", Colors.green, () {})),
                const SizedBox(width: 10),
                Expanded(child: _actionButton("رفض", Colors.redAccent, () {})),
              ],
            )
          ],
        ),
      )),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection(bool isDark, Color cardColor, Color primaryColor) {
    return _glassCard(
      title: "المواعيد القادمة",
      isDark: isDark,
      cardColor: cardColor,
      child: Column(
        children: List.generate(2, (index) => _appointmentItem("مالك جونسون", "09:00 AM", "الخدمة السنوية", isDark, primaryColor)),
      ),
    );
  }

  Widget _appointmentItem(String name, String time, String service, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.calendar_today, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(service, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(bool isDark, Color cardColor) {
    return _glassCard(
      title: "المراجعات الأخيرة",
      isDark: isDark,
      cardColor: cardColor,
      child: Column(
        children: List.generate(2, (index) => _reviewItem("سارة أحمد", "خدمة ممتازة وسريعة جداً!", 5)),
      ),
    );
  }

  Widget _reviewItem(String name, String comment, int rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(children: List.generate(rate, (index) => const Icon(Icons.star, color: Colors.amber, size: 14))),
            ],
          ),
          Text(comment, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
    );
  }

  Widget _glassCard({required String title, required Widget child, required bool isDark, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}