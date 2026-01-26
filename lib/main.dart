import 'package:flutter/material.dart';
import 'package:gear_up_app/pages/Landing/landing.dart';
import 'package:provider/provider.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const GearUpApp(),
    ),
  );
}

class GearUpApp extends StatelessWidget {
  const GearUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة الثيم
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearUp AI',

      // إعدادات الثيم (Light & Dark)
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF137FEC),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial', // يمكنك تغيير الخط لاحقاً
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1323),
      ),

      // الصفحة التي تظهر عند فتح التطبيق
      home: const LandingPage(),
    );
  }
}