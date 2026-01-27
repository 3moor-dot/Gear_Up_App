import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:gear_up_app/pages/Landing/landing.dart';
import 'package:gear_up_app/pages/Customer/Control panel/control_panel.dart';
import 'package:gear_up_app/pages/Customer/Reminder/maintenance_reminders.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearUp AI',
      
      // إعدادات اللغة العربية (RTL)
      locale: const Locale('ar', 'AE'), 
      supportedLocales: const [Locale('ar', 'AE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // إعدادات الثيم
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true, // تفعيل Material 3 لأشكال أحدث للأزرار والكروت
        brightness: Brightness.light,
        primaryColor: const Color(0xFF137FEC),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Cairo', // يفضل استخدام خط Cairo للعربية
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1323),
        fontFamily: 'Cairo',
      ),

      // --- نظام المسارات (Routes) الاحترافي ---
      initialRoute: '/dashboard', // نقطة البداية
      routes: {
        '/landing': (context) => const LandingPage(),
        '/dashboard': (context) => const CustomerDashboardPage(),
        '/reminders': (context) => const MaintenanceRemindersPage(),
        // أضف أي صفحات جديدة هنا لتتمكن من استدعائها بالاسم
      },
    );
  }
}

// كلاس ThemeProvider (تأكد من وجوده في ملف منفصل أو بقائه هنا)
class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}