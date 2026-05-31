import 'package:flutter/material.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';
import 'package:gear_up_app/main.dart';
import 'package:provider/provider.dart';

import '../../components/Hero Section/hero_section.dart';
import '../../components/Features Section/features_section.dart';
import '../../components/How It Works Section/how_it_works_section.dart';
import '../../components/Team Section/team_section.dart';
import '../../components/CTA Section/cta_section.dart';
import '../../components/Footer Section/footer_section.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xff0F172A)
          : const Color(0xffF7F9FD),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: isDark ? const Color(0xff0F172A) : Colors.white,

              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      "assets/logo.png",
                      width: 45,
                      height: 45,
                    ),
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ThemeToggle(
                        isDark: themeProvider.isDark,
                        onToggle: () => themeProvider.toggleTheme(),
                      );
                    },
                  ),

                  const Spacer(),

                  // 🔥 Dark Mode Toggle زي DashboardHeader
                  const SizedBox(width: 10),

                  Row(
                    children: [
                      // 🔹 زر تسجيل الدخول (Secondary)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF137FEC)),
                          foregroundColor: const Color(0xFF137FEC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("تسجيل الدخول"),
                      ),

                      const SizedBox(width: 10),

                      // 🔥 زر ابدأ الآن
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("ابدأ الآن", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SliverList(
              delegate: SliverChildListDelegate(const [
                HeroSection(),
                FeaturesSection(),
                HowItWorksSection(),
                TeamSection(),
                CTASection(),
                FooterSection(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
