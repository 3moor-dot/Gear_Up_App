import 'package:flutter/material.dart';

class TeamSection extends StatelessWidget {
  const TeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    final members = [
      {"name": "Rahma Hassan", "role": "Front End", "avatar": "RH"},
      {"name": "Eman Saleh", "role": "Front End", "avatar": "ES"},
      {"name": "Ali Gamal", "role": "UI / UX", "avatar": "AG"},
      {"name": "Amr Mohamed", "role": "Mobile", "avatar": "AM"},
      {"name": "Gahad Abdollah", "role": "AI", "avatar": "GA"},
      {"name": "Montaha Ahmed", "role": "AI", "avatar": "MA"},
      {"name": "Rawan Adel", "role": "Back End", "avatar": "RA"},
      {"name": "Alshimaa Mohamed", "role": "Back End", "avatar": "SM"},
      {"name": "Youstina Magdy", "role": "Back End", "avatar": "YM"},
      {"name": "Mohamed Abdelfatah", "role": "Back End", "avatar": "MF"},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Text(
            "فريق العمل",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "الفريق المسؤول عن تطوير منصة GearUp",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final member = members[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xff131A2E)
                      : Colors.white,
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
                      radius: 28,
                      backgroundColor: const Color(0xff2563EB),
                      child: Text(
                        member["avatar"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      member["name"]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      member["role"]!,
                      style: const TextStyle(
                        color: Color(0xff2563EB),
                        fontWeight: FontWeight.w600,
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