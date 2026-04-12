import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/Customer/customer_header.dart';
import '../../../components/Customer/customer_sidebar.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _userCars = [];
  Map<String, dynamic>? _selectedCar;

  final List<String> _initialSuggestions = [
    "كيف أحجز موعد صيانة؟",
    "ما هي قطع الغيار المتاحة؟",
    "متى موعد الصيانة القادمة؟",
    "كيف أتابع طلب الصيانة؟",
  ];
  bool _showInitialSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _startNewChat();
    await _fetchUserCars();
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _showInitialSuggestions = true;
      _addMessage(
        "مرحبًا 👋 أنا مساعد GearUp الذكي. اختر سيارتك وابدأ الدردشة!",
        "bot",
      );
    });
  }

  Future<void> _fetchUserCars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken") ?? "";
    try {
      final response = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/customers/cars"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() {
          _userCars = jsonDecode(response.body);
          if (_userCars.isNotEmpty) _selectedCar = _userCars[0];
        });
      }
    } catch (e) {
      debugPrint("Error fetching cars: $e");
    }
  }

  Future<void> _sendMessage({String? quickText}) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // إضافة رسالة المستخدم محلياً
    _addMessage(text, "user", extraData: {"image": _selectedImage?.path});

    File? imageToSend = _selectedImage;
    setState(() {
      _isTyping = true;
      _controller.clear();
      _selectedImage = null;
      _showInitialSuggestions = false;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken") ?? "";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://gearupapp.runasp.net/api/Chatbot/message"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Message'] = text;

      if (_selectedCar != null) {
        request.fields['CarId'] = _selectedCar!['id'].toString();
      }

      if (imageToSend != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Image', imageToSend.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // منطق الـ Deep Parse لمطابقة الويب
        final parsed = _deepParse(data['reply'] ?? data);

        String botText = "";
        if (parsed is Map) {
          botText = parsed['ai_answer'] ?? parsed['reply'] ?? "";
        } else {
          botText = parsed.toString();
        }

        _addMessage(botText, "bot", extraData: parsed);
      } else {
        _addMessage("⚠️ حدث خطأ في الخادم (${response.statusCode})", "bot");
      }
    } catch (e) {
      _addMessage("⚠️ حصل خطأ في الاتصال بالإنترنت.", "bot");
    } finally {
      setState(() => _isTyping = false);
    }
  }

  dynamic _deepParse(dynamic value) {
    if (value is! String) return value;
    try {
      final parsed = jsonDecode(value);
      return _deepParse(parsed);
    } catch (e) {
      return value;
    }
  }

  void _addMessage(String text, String role, {dynamic extraData}) {
    setState(() {
      _messages.add({
        "text": text,
        "role": role,
        "time": DateFormat.jm('ar_EG').format(DateTime.now()),
        "extra": extraData,
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1323) : Colors.white,
      endDrawer: const CustomDrawer(currentRoute: '/customer/chatbot'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            _buildTopTitleBar(isDark),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildChatBubble(_messages[index], isDark, primaryColor),
              ),
            ),
            if (_isTyping) _buildWebLoadingIndicator(isDark),
            _buildBottomArea(isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTitleBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "مساعد GearUp الذكي",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: _startNewChat,
            icon: const Icon(Icons.refresh, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    Map<String, dynamic> msg,
    bool isDark,
    Color primaryColor,
  ) {
    bool isUser = msg['role'] == "user";
    dynamic extra = msg['extra'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildBotAvatar(primaryColor),
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // عرض الصورة إذا كانت موجودة في رسالة المستخدم
                    if (isUser && extra != null && extra['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(extra['image']),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser
                            ? primaryColor
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                      ),
                      child: MarkdownBody(
                        data: msg['text'],
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),

                    // كروت التفاعل (Reminder / Technicians)
                    if (extra != null && extra is Map) ...[
                      if (extra['offersReminder'] == true)
                        _buildReminderCard(
                          extra['reminder'],
                          isDark,
                          primaryColor,
                        ),

                      if (extra['requires_mechanic'] == true)
                        _buildSOSButton(isDark),

                      if (extra['followUpQuestions'] != null)
                        _buildFollowUpQuestions(extra['followUpQuestions']),

                      if (extra['requires_feedback'] == true)
                        _buildFeedbackButtons(isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!isUser) _buildActionButtons(msg['text']),
        ],
      ),
    );
  }

  // أزرار الأسئلة المقترحة بعد رد البوت (مطابقة للويب)
  Widget _buildFollowUpQuestions(dynamic questions) {
    List<dynamic> qs = questions is List ? questions : [];
    if (qs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: qs
            .map(
              (q) => ActionChip(
                label: Text(
                  q.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
                onPressed: () => _sendMessage(quickText: q.toString()),
                backgroundColor: Colors.blue.withOpacity(0.05),
                shape: StadiumBorder(
                  side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildReminderCard(dynamic reminder, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reminder?['title'] ?? "",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            reminder?['description'] ?? "",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _tag("📅 ${reminder?['start_date']} ← ${reminder?['end_date']}"),
              _tag("🔁 ${reminder?['frequency']}"),
              _tag("🕘 ${reminder?['notification_time']}"),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("إنشاء التذكير الآن"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildFeedbackButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "هل كانت هذه النصيحة مفيدة لك؟",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _feedbackBtn("👍 مفيدة", Colors.green),
              const SizedBox(width: 8),
              _feedbackBtn("👎 غير مفيدة", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackBtn(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _buildSOSButton(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/customer/request');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444), // أحمر
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: const Text(
          "🚨 SOS اطلب فني فورًا",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBotAvatar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: primaryColor.withOpacity(0.1),
        child: Icon(Icons.auto_awesome, size: 16, color: primaryColor),
      ),
    );
  }

  Widget _buildActionButtons(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 4),
      child: Row(
        children: [
          _bubbleIcon(
            Icons.copy_rounded,
            () => Clipboard.setData(ClipboardData(text: text)),
          ),
          _bubbleIcon(Icons.thumb_up_outlined, () {}),
          _bubbleIcon(Icons.thumb_down_outlined, () {}),
        ],
      ),
    );
  }

  Widget _bubbleIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.grey),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildWebLoadingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 50, bottom: 10),
        child: Row(children: List.generate(3, (i) => _buildDot(i))),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 200)),
      builder: (context, double value, _) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3 + (0.7 * value)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildBottomArea(bool isDark, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showInitialSuggestions)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _initialSuggestions
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        onPressed: () => _sendMessage(quickText: s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // اختيار السيارة
        if (_userCars.isNotEmpty)
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _userCars.map((car) {
                bool selected = _selectedCar?['id'] == car['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      "${car['make']} ${car['model']}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: selected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCar = car);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        _buildInputArea(isDark, primaryColor),
      ],
    );
  }

  Widget _buildInputArea(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _selectedImage != null
                          ? Icons.image
                          : Icons.attach_file_rounded,
                      color: primaryColor,
                    ),
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setState(() => _selectedImage = File(image.path));
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: "اكتب رسالتك هنا...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF137FEC), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
