import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: const DecorationImage(
                image: AssetImage(
                  "assets/hero.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
          )
              .animate()
              .fade(duration: 700.ms)
              .slideY(begin: .2),

          const SizedBox(height: 30),

          const Text(
            "العناية بالسيارة بطريقة أسهل وأكثر ذكاءً",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            "منصة ذكية مدعومة بالذكاء الاصطناعي تساعدك في إدارة وصيانة سيارتك بسهولة.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("ابدأ الآن"),
            ),
          ),
        ],
      ),
    );
  }
}