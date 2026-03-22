import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../components/Customer/customer_header.dart';
import '../../../components/Customer/customer_sidebar.dart';

class ChatMessage {
  final String text;
  final String role; // 'user' or 'bot'
  final String time;
  final File? image;

  ChatMessage({
    required this.text,
    required this.role,
    required this.time,
    this.image,
  });
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _suggestions = [
    "كيف أحجز موعد صيانة؟",
    "ما هي قطع الغيار المتاحة؟",
    "متى موعد الصيانة القادمة؟",
    "كيف أتابع طلب الصيانة؟",
  ];

  @override
  void initState() {
    super.initState();
    // رسالة الترحيب الأولية
    _messages.add(
      ChatMessage(
        text:
            "مرحبًا 👋 أنا مساعد GearUp الذكي. أقدر أساعدك في الصيانة، الأعطال، المواعيد، وطلبات الخدمة. كيف أساعدك اليوم؟",
        role: 'bot',
        time: DateFormat.jm('ar_EG').format(DateTime.now()),
      ),
    );
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // دالة استخراج الرد كما في كود React تماماً
  String _extractBotReply(dynamic reply) {
    if (reply == null || reply == "") return "تم استلام رسالتك بنجاح.";

    // لو String → جرب تعمله parse
    if (reply is String) {
      String cleaned = reply.trim();

      try {
        final parsed = jsonDecode(cleaned);

        if (parsed is Map) {
          return parsed['ai_answer'] ??
              parsed['reply'] ??
              parsed['message'] ??
              parsed['answer'] ??
              cleaned;
        }
      } catch (_) {
        // مش JSON → كمل عادي
      }

      // تنظيف الـ escape characters
      return cleaned
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\t', ' ');
    }

    // لو object
    if (reply is Map) {
      return reply['ai_answer'] ??
          reply['reply'] ??
          reply['message'] ??
          reply['answer'] ??
          "تم استلام رسالتك.";
    }

    return reply.toString();
  }

  Future<void> _sendMessage({String? text}) async {
    final msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty && _selectedImage == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken") ?? "";

    final userMsg = ChatMessage(
      text: msgText.isEmpty ? "تم إرسال صورة" : msgText,
      role: 'user',
      time: DateFormat.jm('ar_EG').format(DateTime.now()),
      image: _selectedImage,
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      if (text == null) _controller.clear();
      _selectedImage = null;
    });
    _scrollToBottom();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://gearupapp.runasp.net/api/Chatbot/message"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Message'] = msgText;

      if (userMsg.image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Image', userMsg.image!.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = _extractBotReply(data['reply']);

        setState(() {
          _messages.add(
            ChatMessage(
              text: botReply,
              role: 'bot',
              time: DateFormat.jm('ar_EG').format(DateTime.now()),
            ),
          );
        });
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "عذراً، حصل خطأ في الاتصال بالمساعد الذكي.",
            role: 'bot',
            time: DateFormat.jm('ar_EG').format(DateTime.now()),
          ),
        );
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF3F7FB),
      endDrawer: const CustomDrawer(currentRoute: '/customer/chatbot'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            _buildAIBanner(primaryColor),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length)
                    return _buildTypingIndicator(isDark);
                  return _buildMessageBubble(
                    _messages[index],
                    isDark,
                    primaryColor,
                  );
                },
              ),
            ),
            if (_messages.length <= 1) _buildSuggestions(primaryColor, isDark),
            _buildInputArea(primaryColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBanner(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "المساعد الذكي",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "GearUp AI • متصل الآن",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () =>
                setState(() => _messages.removeRange(1, _messages.length)),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark, Color primaryColor) {
    bool isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(Icons.smart_toy, Colors.black),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? primaryColor
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: isUser
                          ? Radius.zero
                          : const Radius.circular(15),
                      bottomRight: isUser
                          ? const Radius.circular(15)
                          : Radius.zero,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.image != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              msg.image!,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      isUser
                          ? Text(
                              msg.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            )
                          : MarkdownBody(
                              data: msg.text,
                              selectable: true,
                              softLineBreak: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                listBullet: TextStyle(color: primaryColor),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(Icons.person, primaryColor),
        ],
      ),
    );
  }

  Widget _buildAvatar(IconData icon, Color color) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          "GearUp AI يكتب الآن...",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSuggestions(Color primaryColor, bool isDark) {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _suggestions
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _sendMessage(text: s),
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputArea(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "اكتب رسالتك هنا...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: primaryColor,
                child: IconButton(
                  onPressed: () => _sendMessage(),
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
