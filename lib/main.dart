import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gear_up_app/pages/Notification/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:gear_up_app/pages/LogIn/log_in.dart';
import 'package:gear_up_app/pages/Registration/register.dart';
import 'package:gear_up_app/pages/Forgot_Password/forgot_password.dart';
import 'package:gear_up_app/pages/Verfiy_Account/verfiy_account.dart';
import 'package:gear_up_app/pages/Notification/notifications_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:gear_up_app/pages/Customer/Control panel/control_panel.dart';
import 'package:gear_up_app/pages/Customer/Reminder/maintenance_reminders.dart';
import 'package:gear_up_app/pages/Customer/Service History/service_history.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Bookings/maintenance_bookings.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Request/maintenance_request.dart';
import 'package:gear_up_app/pages/Customer/Profile_Settings/profile_settings.dart';
import 'package:gear_up_app/pages/Customer/Chatbot/chatbot.dart';

import 'package:gear_up_app/pages/Mechanic/Mechanic_Dashboard/mechanic_dashboard.dart';
import 'package:gear_up_app/pages/Mechanic/Request/request_history.dart';
import 'package:gear_up_app/pages/Mechanic/Schedule/schedule.dart';
import 'package:gear_up_app/pages/Mechanic/Booking/booking.dart';
import 'package:gear_up_app/pages/Mechanic/Reviewing/reviewing.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Mprofile.dart';

// 🔥 دالة الـ Background Handler الخاصة بآي أو إس وأندرويد والتطبيق مقفول تماماً
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("إشعار في الخلفية: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة الفايربيز

  // 1. إعداد معالج الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. طلب صلاحيات الإشعارات للآيفون (iOS)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('المستخدم وافق على الصلاحيات في الآيفون');

    // 3. السطر السحري: إجبار الآيفون على إظهار الإشعار كـ Banner والتطبيق مفتوح!
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // 🔥 التعديل الجوهري: تغليف الـ MyApp بالـ MultiProvider هنا فوق الشجرة بالكامل
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationService(),
        ), // عشان تشتغل في الـ Login والشاشات التانية
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الآن السطر ده هيشتغل تمام لأن الـ ThemeProvider أصبح فوق الـ MyApp في الشجرة
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearUp',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF137FEC),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF137FEC),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
      ),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

      // الدعم اللغوي للعربي
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG')],

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/verify-account': (context) => const VerificationPage(),
        '/notification': (context) => const NotificationsPage(),

        /* CUSTOMER PAGES */
        '/customer/dashboard': (context) => const CustomerDashboardPage(),
        '/customer/reminders': (context) => const MaintenanceRemindersPage(),
        '/customer/servicehistory': (context) => const ServiceHistoryPage(),
        '/customer/bookings': (context) => const MaintenanceBookingsPage(),
        '/customer/request': (context) => const MaintenanceRequestScreen(),
        '/customer/profilesettings': (context) => const ProfileSettingsPage(),
        '/customer/chatbot': (context) => const ChatbotPage(),

        /* MECHANIC PAGES */
        '/mechanic/dashboard': (context) => const MachineDashboard(),
        '/mechanic/request-history': (context) => const MRequestHistory(),
        '/mechanic/schedule': (context) => const SchedulePage(),
        '/mechanic/booking': (context) => const BookingPage(),
        '/mechanic/reviewing': (context) => const ReviewsPage(),
        '/mechanics/machineprofile': (context) => const MProfilePage(),
      },
    );
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
