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
  static const String chatStorageKey = "gearup_chat_messages";
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
    await _loadSavedChat();

    if (_messages.isEmpty) {
      _startNewChat();
    }

    await _fetchUserCars();
  }

  Future<void> _startNewChat() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(chatStorageKey);

    setState(() {
      _messages.clear();
      _showInitialSuggestions = true;
    });

    _addMessage(
      "مرحبًا 👋 أنا مساعد GearUp الذكي. اختر سيارتك وابدأ الدردشة!",
      "bot",
    );
  }

  Future<void> _saveEmergencyRequestData(dynamic extra) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool("is_from_chatbot", true);

      if (extra['car_id'] != null) {
        await prefs.setString('booking_car_id', extra['car_id'].toString());
      }

      if (extra['issue_summary'] != null) {
        await prefs.setString(
          'issue_summary',
          extra['issue_summary'].toString(),
        );
      }

      if (extra['recommended_mechanics'] != null) {
        await prefs.setString(
          'recommended_mechanics',
          jsonEncode(extra['recommended_mechanics']),
        );
      }
    } catch (e) {
      debugPrint("Save booking data error: $e");
    }
  }

  Future<void> _loadSavedChat() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(chatStorageKey);

    if (saved != null) {
      final data = jsonDecode(saved);

      setState(() {
        _messages.clear();
        _messages.addAll(List<Map<String, dynamic>>.from(data));
        _showInitialSuggestions = _messages.length <= 1;
      });
    }
  }

  Future<void> _sendFeedback({
    required String userMessage,
    required String botMessage,
    required int feedback,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("userToken");

    await http.post(
      Uri.parse("https://gearupapp.runasp.net/api/Chatbot/feedback"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userMessageContent": userMessage,
        "botMessageContent": botMessage,
        "feedback": feedback,
      }),
    );
  }

  Future<void> _fetchUserCars() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("userToken") ?? "";

    try {
      final response = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/customers/cars"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _userCars = data["cars"] ?? [];

          if (_userCars.isNotEmpty) {
            _selectedCar = _userCars.first;
          }
        });

        print("Cars: $_userCars");
      }
      print(response.body);
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
        final rawData = jsonDecode(response.body);

        dynamic replyData;

        if (rawData is Map &&
            rawData.containsKey("success") &&
            rawData.containsKey("reply")) {
          replyData = rawData["reply"];
        } else {
          replyData = rawData;
        }

        final parsed = _deepParse(replyData);

        String botText = "";
        if (parsed is Map) {
          botText = parsed['ai_answer'] ?? parsed['reply'] ?? "";
        } else {
          botText = parsed.toString();
        }

        if (parsed is Map && parsed['requires_mechanic'] == true) {
          await _saveBookingData(parsed);
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
    Future<void> saveMessages() async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(chatStorageKey, jsonEncode(_messages));
    }

    setState(() {
      _messages.add({
        "text": text,
        "role": role,
        "time": DateFormat.jm('ar_EG').format(DateTime.now()),
        "extra": extraData,
      });
    });

    saveMessages();
    _scrollToBottom();
  }

  Future<void> _saveBookingData(dynamic extra) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (extra['car_id'] != null) {
        await prefs.setString('booking_car_id', extra['car_id'].toString());
      }

      if (extra['recommended_mechanics'] != null) {
        await prefs.setString(
          'recommended_mechanics',
          jsonEncode(extra['recommended_mechanics']),
        );
      }
    } catch (e) {
      debugPrint("Save booking data error: $e");
    }
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
            onPressed: () async {
              await _startNewChat();
            },
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
                    if (isUser &&
                        extra != null &&
                        extra['image'] != null &&
                        File(extra['image']).existsSync())
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

                      if (extra['requires_mechanic'] == true &&
                          extra['is_emergency'] == true)
                        _buildSOSButton(isDark, extra),
                      if (extra['requires_mechanic'] == true &&
                          extra['is_emergency'] == false)
                        _buildBookingButton(),
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
              _feedbackBtn("👍 مفيدة", Colors.green, () {
                _sendFeedback(
                  userMessage: _messages.lastWhere(
                    (m) => m['role'] == 'user',
                  )['text'],
                  botMessage: _messages.lastWhere(
                    (m) => m['role'] == 'bot',
                  )['text'],
                  feedback: 1,
                );
              }),
              const SizedBox(width: 8),
              _feedbackBtn("👎 غير مفيدة", Colors.red, () {
                _sendFeedback(
                  userMessage: _messages.lastWhere(
                    (m) => m['role'] == 'user',
                  )['text'],
                  botMessage: _messages.lastWhere(
                    (m) => m['role'] == 'bot',
                  )['text'],
                  feedback: 0,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackBtn(String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, color: color)),
      ),
    );
  }

  Widget _buildSOSButton(bool isDark, dynamic extra) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: () async {
          try {
            final prefs = await SharedPreferences.getInstance();

            // ✅ مهم جداً
            await prefs.setBool("is_from_chatbot", true);

            // ✅ نفس الـ keys اللي شاشة الطلب بتقرأها
            if (extra['car_id'] != null) {
              await prefs.setString(
                'booking_car_id',
                extra['car_id'].toString(),
              );
            }

            if (extra['issue_summary'] != null) {
              await prefs.setString(
                'issue_summary',
                extra['issue_summary'].toString(),
              );
            }

            // ✅ الميكانيكيين
            if (extra['recommended_mechanics'] != null) {
              final mechanics = List<String>.from(
                extra['recommended_mechanics'].map((e) => e.toString()),
              );

              await prefs.setStringList('recommended_mechanics', mechanics);
            }

            // ✅ روح للصفحة
            Navigator.pushNamed(
              context,
              '/customer/request',
              arguments: {"fromChatbot": true},
            );
          } catch (e) {
            debugPrint("SOS save error: $e");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
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

  Widget _buildBookingButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/customer/bookings');
        },
        child: const Text("🛠️ احجز صيانة"),
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
          _bubbleIcon(Icons.copy_rounded, () async {
            await Clipboard.setData(ClipboardData(text: text));

            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("تم نسخ الرسالة")));
            }
          }),
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
        if (_selectedImage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -5,
                  left: -5,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ),
              ],
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
                  if (_userCars.isNotEmpty)
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PopupMenuButton<Map<String, dynamic>>(
                      onSelected: (car) {
                        setState(() {
                          _selectedCar = car;
                        });
                      },
                      itemBuilder: (context) => _userCars.map((car) {
                        return PopupMenuItem<Map<String, dynamic>>(
                          value: car,
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${car['brand']} ${car['model']}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_car,
                              size: 16,
                              color: Color(0xFF137FEC),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCar == null
                                  ? "Car"
                                  : "${_selectedCar!['brand']}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
