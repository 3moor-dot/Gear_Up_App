import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gear_up_app/components/ThemeToggle/theme_toggle.dart';
import 'package:gear_up_app/pages/LogIn/log_in.dart'; // تأكد من المسار الصحيح لملفك

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const GearUpApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class GearUpApp extends StatelessWidget {
  const GearUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF137FEC),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1323),
        primaryColor: const Color(0xFF137FEC),
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // استدعاء الـ Provider هنا لاستخدامه في الـ NavBar
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- NAVBAR ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/gearup-logo.png',
                      width: 60,
                      errorBuilder: (c, e, s) => CircleAvatar(
                        backgroundColor: isDark
                            ? Colors.white
                            : Colors.grey[200],
                        child: const Icon(Icons.settings),
                      ),
                    ),
                    Row(
                      children: [
                        _navBtn("اشترك", const Color(0xFF137FEC), Colors.white),
                        const SizedBox(width: 8),

                        // --- التعديل يبدأ هنا ---
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ), // تأكد أن اسم الكلاس هو LoginPage
                            );
                          },
                          child: _navBtn(
                            "تسجيل دخول",
                            isDark ? Colors.grey[800]! : Colors.black,
                            Colors.white,
                          ),
                        ),

                        // --- التعديل ينتهي هنا ---
                        const SizedBox(width: 10),
                        ThemeToggle(
                          isDark: themeProvider.isDark,
                          onToggle: () => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // HERO SECTION
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      "العناية بالسيارة بطريقة\nذكية وسهلة تبدأ من هنا",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "تعمل منصة GearUp المدعومة بالذكاء الاصطناعي على تبسيط الصيانة والإصلاحات.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _heroBtn(
                          "ابدأ الآن",
                          const Color(0xFF137FEC),
                          Colors.white,
                          140,
                        ),
                        const SizedBox(width: 10),
                        _heroBtn(
                          "المزيد",
                          isDark ? Colors.white : Colors.black,
                          isDark ? Colors.black : Colors.white,
                          100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/car-dashboard.png',
                        errorBuilder: (c, e, s) => Container(
                          height: 180,
                          width: double.maxFinite,
                          color: Colors.blueGrey[100],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // FEATURES
              _sectionTitle("خدماتنا"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _featureCard(
                      Icons.psychology,
                      "تشخيصات AI",
                      "تحليل دقيق لمشاكل السيارة",
                      isDark,
                    ),
                    _featureCard(
                      Icons.build,
                      "صيانة ذكية",
                      "جدولة وإدارة الإصلاحات",
                      isDark,
                    ),
                  ],
                ),
              ),

              // HOW IT WORKS
              _sectionTitle("كيف يعمل"),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2237) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _stepItem(Icons.directions_car, "1. أدخل بيانات السيارة"),
                    _stepItem(Icons.psychology, "2. تشخيص ذكي"),
                    _stepItem(Icons.verified_user, "3. احجز ميكانيكي"),
                  ],
                ),
              ),

              // TEAM SECTION
              _sectionTitle("فريق العمل"),
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 6,
                  itemBuilder: (context, index) => _teamCard(isDark),
                ),
              ),

              // CTA SECTION
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF137FEC,
                  ).withOpacity(isDark ? 0.6 : 1.0),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    const Text(
                      "جاهزون للبدء؟",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _heroBtn("سجل الآن", Colors.black, Colors.white, 200),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  "GearUp © 2026",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Helpers ---
  Widget _navBtn(String text, Color bg, Color clr) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );

  Widget _heroBtn(String text, Color bg, Color clr, double width) => Container(
    width: width,
    height: 45,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(color: clr, fontWeight: FontWeight.bold),
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 15),
    child: Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );

  Widget _featureCard(IconData icon, String title, String desc, bool isDark) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131A2E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _stepItem(IconData icon, String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF137FEC)),
        const SizedBox(width: 15),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _teamCard(bool isDark) => Container(
    width: 160,
    margin: const EdgeInsets.only(right: 15),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF137FEC).withOpacity(isDark ? 0.5 : 1.0),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(50),
        bottomLeft: Radius.circular(50),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white,
          backgroundImage: const AssetImage('assets/avatar-team.png'),
        ),
        const SizedBox(height: 10),
        const Text(
          "ALI GAMAL",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const Text(
          "UI / UX",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.link, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Icon(Icons.language, color: Colors.white, size: 18),
          ],
        ),
      ],
    ),
  );
}

// ملاحظة: يمكنك حذف كلاس ThemeToggleWidget القديم من أسفل الملف لأنه لم يعد مستخدماً.
