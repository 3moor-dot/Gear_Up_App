import 'package:flutter/material.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = [
      {
        "number": "1",
        "title": "أدخل بيانات سيارتك",
        "desc": "أدخل بيانات السيارة أو رقم اللوحة للبدء.",
        "icon": Icons.directions_car,
      },
      {
        "number": "2",
        "title": "تحليل ذكي",
        "desc": "الذكاء الاصطناعي يحلل الحالة ويقترح الأعطال المحتملة.",
        "icon": Icons.psychology,
      },
      {
        "number": "3",
        "title": "تحديد الأعطال",
        "desc": "عرض الأسباب المتوقعة والحلول والإجراءات المقترحة.",
        "icon": Icons.search,
      },
      {
        "number": "4",
        "title": "تنفيذ ومتابعة",
        "desc": "تنفيذ الصيانة ومتابعة حالة السيارة والخدمة.",
        "icon": Icons.build,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Text(
            "كيف يعمل GearUp",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "خطوات بسيطة تبدأ من إدخال البيانات وتنتهي بتجربة صيانة أذكى وأسهل.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 30),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final step = steps[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff131A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xff2563EB),
                      child: Text(
                        step["number"] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xff2563EB).withOpacity(.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        step["icon"] as IconData,
                        color: const Color(0xff2563EB),
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      step["title"] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      step["desc"] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
