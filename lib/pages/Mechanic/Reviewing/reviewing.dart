import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReviewModel {
  final int id;
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userName: json['userName'] ?? "مستخدم",
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment'] ?? "",
      createdAt: json['createdAt'] ?? "",
    );
  }
}

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final Color primaryColor = const Color(0xFF137FEC);

  List<ReviewModel> reviews = [];

  bool loadingReviews = true;
  bool loadingRating = true;

  dynamic averageRating = "--";

  String? token;
  String? mechanicId;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  // ================= INIT =================

  Future<void> initializeData() async {
    await loadToken();

    if (mechanicId == null) {
      debugPrint("❌ mechanicId = null");

      setState(() {
        loadingReviews = false;
        loadingRating = false;
      });

      return;
    }

    debugPrint("✅ mechanicId: $mechanicId");

    await Future.wait([fetchAverageRating(), fetchReviews()]);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("userToken");

    if (token == null) {
      debugPrint("❌ No token found");
      return;
    }

    mechanicId = getMechanicId(token!);
  }

  // ================= JWT =================

  String? getMechanicId(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final data = jsonDecode(payload);

      debugPrint("🔍 JWT Payload: $data");

      return data["sub"]?.toString() ??
          data["id"]?.toString() ??
          data["userId"]?.toString() ??
          data["mechanicId"]?.toString();
    } catch (e) {
      debugPrint("❌ Token parse failed: $e");
      return null;
    }
  }

  // ================= FETCH REVIEWS =================

  Future<void> fetchReviews() async {
    try {
      setState(() => loadingReviews = true);

      final url =
          "https://gearupapp.runasp.net/api/mechanics/mechanic/$mechanicId/latest?count=50";

      debugPrint("URL => $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("STATUS CODE => ${response.statusCode}");
      debugPrint("BODY => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> reviewsData = [];

        // لو الـ API راجع Array مباشر
        if (data is List) {
          reviewsData = data;
        }
        // لو راجع object فيه reviews
        else if (data is Map<String, dynamic>) {
          if (data["reviews"] != null) {
            reviewsData = data["reviews"];
          } else if (data["data"] != null) {
            reviewsData = data["data"];
          } else if (data["items"] != null) {
            reviewsData = data["items"];
          }
        }

        debugPrint("REVIEWS LENGTH => ${reviewsData.length}");

        setState(() {
          reviews = reviewsData.map((e) => ReviewModel.fromJson(e)).toList();
        });
      } else {
        debugPrint("FAILED TO LOAD REVIEWS");

        setState(() {
          reviews = [];
        });
      }
    } catch (e) {
      debugPrint("FETCH REVIEWS ERROR => $e");

      setState(() {
        reviews = [];
      });
    } finally {
      setState(() {
        loadingReviews = false;
      });
    }
  }

  // ================= FETCH AVG RATING =================

  Future<void> fetchAverageRating() async {
    try {
      setState(() => loadingRating = true);

      final response = await http.get(
        Uri.parse(
          "https://gearupapp.runasp.net/api/mechanics/mechanic/$mechanicId/average-rating",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("RATING STATUS: ${response.statusCode}");
      debugPrint("RATING BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        dynamic ratingValue = "0";

        if (data is num) {
          ratingValue = data.toString();
        } else if (data is Map<String, dynamic>) {
          ratingValue =
              data["avgRating"] ??
              data["averageRating"] ??
              data["rating"] ??
              "0";
        }

        setState(() {
          averageRating = ratingValue;
        });
      } else {
        setState(() {
          averageRating = "0";
        });
      }
    } catch (e) {
      debugPrint("❌ FETCH RATING ERROR: $e");

      setState(() {
        averageRating = "0";
      });
    } finally {
      setState(() => loadingRating = false);
    }
  }

  // ================= STAR PERCENTAGES =================

  List<int> getStarPercentages() {
    final total = reviews.length;

    if (total == 0) {
      return [0, 0, 0, 0, 0];
    }

    final counts = [5, 4, 3, 2, 1].map((star) {
      return reviews.where((r) => r.rating == star).length;
    }).toList();

    return counts.map((count) {
      return ((count / total) * 100).round();
    }).toList();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final starPercents = getStarPercentages();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF9FAFB),
      endDrawer: const MachineDrawer(currentRoute: '/mechanic/reviewing'),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              if (MediaQuery.of(context).size.width > 1024)
                const SizedBox(
                  width: 280,
                  child: MachineDrawer(currentRoute: '/mechanic/reviewing'),
                ),

              Expanded(
                child: Column(
                  children: [
                    const MachineHeader(),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHeader(isDark),

                          const SizedBox(height: 20),

                          _buildRatingSummary(isDark, starPercents),

                          const SizedBox(height: 24),

                          Text(
                            loadingReviews
                                ? "جميع المراجعات"
                                : "جميع المراجعات (${reviews.length})",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (loadingReviews)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (reviews.isEmpty)
                            _buildEmptyState(isDark)
                          else
                            ...reviews.map(
                              (review) => _buildReviewCard(review, isDark),
                            ),
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

  // ================= HEADER =================

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "التقييمات والمراجعات",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "عرض تقييمات العملاء وتحليل الأداء",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ================= RATING SUMMARY =================

  Widget _buildRatingSummary(bool isDark, List<int> starPercents) {
    final parsedRating = double.tryParse(averageRating.toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            loadingRating ? "..." : averageRating.toString(),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 20,
                color: index < parsedRating.round()
                    ? Colors.amber
                    : Colors.grey[400],
              );
            }),
          ),

          const SizedBox(height: 10),

          Text(
            "بناءً على ${reviews.length} مراجعة",
            style: const TextStyle(color: Colors.grey),
          ),

          const Divider(height: 40),

          _buildRatingBar(5, starPercents[0], isDark),

          _buildRatingBar(4, starPercents[1], isDark),

          _buildRatingBar(3, starPercents[2], isDark),

          _buildRatingBar(2, starPercents[3], isDark),

          _buildRatingBar(1, starPercents[4], isDark),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, int percent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$star",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),

          const SizedBox(width: 4),

          const Icon(Icons.star, color: Colors.orange, size: 14),

          const SizedBox(width: 10),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                color: primaryColor,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            "$percent%",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= REVIEW CARD =================

  Widget _buildReviewCard(ReviewModel review, bool isDark) {
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
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryColor,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : "U",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      formatDate(review.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 15,
                    color: index < review.rating
                        ? Colors.amber
                        : Colors.grey[400],
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // ================= EMPTY =================

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          "لا توجد مراجعات حالياً",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // ================= DATE FORMAT =================

  String formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);

      return "${parsed.day}/${parsed.month}/${parsed.year}";
    } catch (_) {
      return date;
    }
  }
}
