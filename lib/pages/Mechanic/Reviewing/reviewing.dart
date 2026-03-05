import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';

class Review {
  final int id;
  final String name;
  final String date;
  final int rating;
  final String comment;
  final String avatar;
  Reply? reply;

  Review({
    required this.id,
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    required this.avatar,
    this.reply,
  });
}

class Reply {
  final String text;
  final String date;
  final String author;

  Reply({
    required this.text,
    required this.date,
    required this.author,
  });
}

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  int? openReplyId;
  final TextEditingController _replyController = TextEditingController();

  // البيانات التجريبية
  List<Review> reviews = [
    Review(
      id: 1,
      name: "جون دوج",
      date: "12 مارس 2024",
      rating: 5,
      comment: "خدمة ممتازة وسريعة، الشغل احترافي جدًا والسعر مناسب. أكيد هتعامل معاهم تاني.",
      avatar: "https://i.pravatar.cc/100?img=11",
    ),
    Review(
      id: 2,
      name: "أحمد علي",
      date: "10 مارس 2024",
      rating: 4,
      comment: "التجربة كانت كويسة جدًا، بس اتأخروا شوية في التسليم.",
      avatar: "https://i.pravatar.cc/100?img=12",
    ),
  ];

  void _handleSendReply(int reviewId) {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      final index = reviews.indexWhere((r) => r.id == reviewId);
      reviews[index].reply = Reply(
        text: _replyController.text,
        date: "الآن",
        author: "إدارة الورشة",
      );
      _replyController.clear();
      openReplyId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB),
      endDrawer: const MachineDrawer(currentRoute: '/mechanic/reviewing'),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const MachineHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 20),
                    _buildRatingSummary(isDark, primaryColor),
                    const SizedBox(height: 24),
                    Text(
                      "جميع المراجعات (${reviews.length})",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...reviews.map((review) => _buildReviewCard(review, isDark, primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الهيدر العلوي ---
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("التقييمات والمراجعات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("عرض تقييمات العملاء والرد عليها", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  // --- ملخص التقييمات ---
  Widget _buildRatingSummary(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text("4.8", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(Icons.star, color: Colors.yellow[700], size: 20)),
          ),
          const SizedBox(height: 8),
          Text("بناءً على ${reviews.length} مراجعة", style: const TextStyle(color: Colors.grey)),
          const Divider(height: 40),
          _buildRatingBar(5, 0.82, isDark, primaryColor),
          _buildRatingBar(4, 0.50, isDark, primaryColor),
          _buildRatingBar(3, 0.20, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double percent, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text("$star", style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              color: primaryColor,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
          Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- كارت المراجعة الواحدة ---
  Widget _buildReviewCard(Review review, bool isDark, Color primaryColor) {
    bool isReplyOpen = openReplyId == review.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(review.avatar), radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(review.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Row(children: List.generate(5, (i) => Icon(Icons.star, color: i < review.rating ? Colors.yellow[700] : Colors.grey[300], size: 14))),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(fontSize: 14, height: 1.5)),
          
          if (review.reply != null) _buildReplyBox(review.reply!, isDark, primaryColor),
          
          if (review.reply == null) 
            TextButton(
              onPressed: () => setState(() => openReplyId = isReplyOpen ? null : review.id),
              child: Text(isReplyOpen ? "إلغاء" : "رد على المراجعة", style: TextStyle(color: primaryColor, fontSize: 13)),
            ),

          if (isReplyOpen) _buildReplyInput(review.id, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildReplyBox(Reply reply, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.05) : Colors.blue.withOpacity(0.03),
        border: Border(right: BorderSide(color: primaryColor, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: primaryColor, radius: 12, child: const Text("M", style: TextStyle(color: Colors.white, fontSize: 10))),
              const SizedBox(width: 8),
              Text(reply.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              Text(reply.date, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(reply.text, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildReplyInput(int reviewId, bool isDark, Color primaryColor) {
    return Column(
      children: [
        TextField(
          controller: _replyController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "اكتب ردك هنا...",
            filled: true,
            fillColor: isDark ? const Color(0xFF131c2f) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleSendReply(reviewId),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text("إرسال الرد"),
          ),
        )
      ],
    );
  }
}