import 'package:flutter/material.dart';

class BookingDetailsPage extends StatefulWidget {
  final int bookingId;
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final TextEditingController _messageController = TextEditingController();

  // بيانات تجريبية تحاكي الكود الخاص بك
  final Map<String, dynamic> booking = {
    "number": "8789-12456",
    "client": {
      "name": "جون لورانس",
      "phone": "(555) 123-4567",
      "avatar": "https://i.pravatar.cc/100?img=1",
    },
    "car": {"model": "2021 Toyota Camry", "plate": "XYZ-1236"},
    "service": "فحص الفرامل وتغيير الزيت",
    "date": "October 26, 2026 at 2:00 PM",
    "notes": "السيارة تُصدر صوت من الفرامل الأمامية اليمنى عند الضغط على الفرامل أثناء السرعة العالية",
    "messages": [
      {"id": 1, "from": "client", "text": "ممكن أعرف التكلفة التقريبية قبل الحضور؟", "time": "10:30 AM"},
      {"id": 2, "from": "mechanic", "text": "التكلفة عادة بين 200–300 ريال، والفحص النهائي يتم عند الحضور.", "time": "10:35 AM"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("تفاصيل الحجز", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(isDark),
                  const SizedBox(height: 20),
                  _buildDetailsCard(isDark),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  const Text("المحادثة مع العميل", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildChatSection(isDark, primaryColor),
                ],
              ),
            ),
            _buildMessageInput(isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  // --- كارت الحالة ---
  Widget _buildStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("مراجعة طلب الحجز", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("رقم: ${booking['number']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text("في انتظار الموافقة", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- كارت تفاصيل الطلب ---
  Widget _buildDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow("العميل", booking['client']['name'], isDark),
          _detailRow("الهاتف", booking['client']['phone'], isDark),
          _detailRow("العربة", booking['car']['model'], isDark),
          _detailRow("الخدمة", booking['service'], isDark),
          _detailRow("التاريخ", booking['date'], isDark),
          const Divider(height: 30),
          const Text("ملاحظات:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(booking['notes'], style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // --- أزرار الإجراءات ---
  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionBtn("الموافقة", Colors.green, Icons.check_circle),
        _actionBtn("رفض الحجز", Colors.red, Icons.cancel),
        _actionBtn("اقتراح وقت", Colors.orange, Icons.access_time_filled),
      ],
    );
  }

  Widget _actionBtn(String text, Color color, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  // --- قسم الدردشة ---
  Widget _buildChatSection(bool isDark, Color primaryColor) {
    List messages = booking['messages'];
    return Column(
      children: messages.map((msg) {
        bool isMe = msg['from'] == "mechanic";
        return Align(
          alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? primaryColor : (isDark ? const Color(0xFF1a2332) : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 13)),
                const SizedBox(height: 4),
                Text(msg['time'], style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- إدخال الرسائل ---
  Widget _buildMessageInput(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "اكتب رسالة...",
                filled: true,
                fillColor: isDark ? const Color(0xFF131c2f) : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: primaryColor,
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }
}