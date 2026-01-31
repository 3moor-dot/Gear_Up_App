import 'package:flutter/material.dart';

class StepTwoMechanics extends StatefulWidget {
  final VoidCallback onBack;
  const StepTwoMechanics({super.key, required this.onBack});

  @override
  State<StepTwoMechanics> createState() => _StepTwoMechanicsState();
}

class _StepTwoMechanicsState extends State<StepTwoMechanics> {
  // بيانات الميكانيكيين (نفس الداتا الخاصة بك)
  final List<Map<String, dynamic>> mechanics = [
    {
      "id": 1,
      "name": "كراج مايك الأوروبي",
      "rate": 4.9,
      "reviews": 142,
      "price": "180 EGP - 220 EGP",
      "tags": ["الفرامل", "تعليق", "أوروبي"],
    },
    {
      "id": 2,
      "name": "كراج مايك الأوروبي",
      "rate": 4.9,
      "reviews": 142,
      "price": "180 EGP - 220 EGP",
      "tags": ["الفرامل", "تعليق", "أوروبي"],
    },
  ];

  String selectedSort = "موصى به";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. الفلاتر السريعة (Horizontal Filters)
        _sectionTitle("فرز حسب"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // للبدء من اليمين
          child: Row(
            children: ["موصى به", "أدنى سعر", "الأعلى تقييماً"].map((filter) {
              bool isSelected = selectedSort == filter;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) => setState(() => selectedSort = filter),
                  selectedColor: const Color(0xFF137FEC),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 25),

        // 2. العنوان وعدد النتائج
        const Text(
          "وجدنا 12 ميكانيكيًا بالقرب منك",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 15),

        // 3. قائمة الميكانيكيين
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mechanics.length,
          itemBuilder: (context, index) {
            final mech = mechanics[index];
            return _buildMechanicCard(mech, isDark);
          },
        ),

        const SizedBox(height: 30),

        // 4. أزرار التحكم السفلية
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {}, // تأكيد الطلب
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("تأكيد الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("رجوع", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
      );

  Widget _buildMechanicCard(Map<String, dynamic> mech, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF137FEC).withOpacity(0.05) : const Color(0xFFD6E9FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // تفاصيل الميكانيكي
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(mech['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF137FEC))),
                        Text(mech['price'], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        Text("${mech['rate']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 5),
                        Text("(${mech['reviews']} تقييم)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "متخصصون في السيارات الأوروبية بخبرة تزيد عن 15 عاماً",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    // التاجات (Tags)
                    Wrap(
                      spacing: 5,
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.start,
                      children: (mech['tags'] as List).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                        child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 8)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // صورة الميكانيكي
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child:  Image.asset("assets/img2.png") // استبدلها بـ Image.network
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // زر الاختيار داخل الكارد
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("اختيار الميكانيكي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }
}