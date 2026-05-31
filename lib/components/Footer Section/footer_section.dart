import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      color: isDark
          ? const Color(0xff0B1120)
          : const Color(0xffF3F4F6),
      child: Column(
        children: [
          const Icon(
            Icons.car_repair,
            size: 45,
            color: Color(0xff2563EB),
          ),

          const SizedBox(height: 15),

          Text(
            "GearUp",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "منصة ذكية لإدارة وصيانة السيارات",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.language),
              SizedBox(width: 20),
              Icon(Icons.facebook),
              SizedBox(width: 20),
              Icon(Icons.email),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "© 2026 GearUp. All Rights Reserved",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? Colors.white54
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}