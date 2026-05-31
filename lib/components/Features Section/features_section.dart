import 'package:flutter/material.dart';
import '../../components/Feature Card/feature_card.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.psychology,
        "تشخيص ذكي",
        "تحليل سريع ودقيق للأعطال"
      ),
      (
        Icons.build,
        "إدارة الورش",
        "إدارة الطلبات والخدمات"
      ),
      (
        Icons.bar_chart,
        "تقارير ذكية",
        "تقارير دقيقة للأداء"
      ),
      (
        Icons.shopping_cart,
        "قطع الغيار",
        "إدارة المخزون والطلبات"
      ),
      (
        Icons.calendar_month,
        "الحجوزات",
        "حجز المواعيد بسهولة"
      ),
      (
        Icons.support_agent,
        "الدعم",
        "متابعة مستمرة للعملاء"
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "كل ما تحتاجه في مكان واحد",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          GridView.builder(
            itemCount: features.length,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: .75,
            ),

            itemBuilder: (_, i) {
              return FeatureCard(
                icon: features[i].$1,
                title: features[i].$2,
                description: features[i].$3,
              );
            },
          ),
        ],
      ),
    );
  }
}