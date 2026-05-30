import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/itransport.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 تم تفعيل حزمة فايربيز للإشعارات
import 'notification_model.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationItem> notifications = [];
  HubConnection? _hubConnection;
  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? token;
  String? userRole;
  bool isShaking = false;

  // خريطة العناوين للحجوزات زي الرياكت بالظبط
  final Map<String, String> bookingTitleMap = {
    "New Booking Request": "طلب حجز جديد 📋",
    "Booking Accepted": "تم قبول الحجز ✅",
    "Booking Rejected": "تم رفض الحجز ❌",
    "Booking Cancelled": "تم إلغاء الحجز 🚫",
    "Booking Rescheduled": "تم تغيير موعد الحجز 📅",
    "Booking Completed": "تم إكمال الحجز 🎉",
    "Booking Status Updated": "تحديث حالة الحجز 🔄",
  };

  // خريطة رسائل الحجوزات لتطابق نصوص الويب بالظبط
  final Map<String, String> bookingMessageMap = {
    "New Booking Request": "لديك طلب حجز جديد في انتظار مراجعتك.",
    "Booking Accepted": "تم قبول طلب الحجز الخاص بك بنجاح.",
    "Booking Rejected": "نعتذر، تم رفض طلب الحجز من قبل الطرف الآخر.",
    "Booking Cancelled": "تم إلغاء موعد الحجز.",
    "Booking Rescheduled": "تمت إعادة جدولة الحجز إلى موعد جديد.",
    "Booking Completed": "تم الانتهاء من تقديم الخدمة بنجاح.",
  };

  // 🔥 دالة الـ init المحدثة تترجم رقم الـ role تلقائياً ليتوافق مع الويب والموبايل معاً
  Future<void> init({required String userToken, required dynamic role}) async {
    token = userToken;
    
    // ترجمة الـ role القادم (سواء كان 1 و 2 أو نصوص)
    if (role == 1 || role.toString().toLowerCase() == 'customer') {
      userRole = 'customer';
    } else if (role == 2 || role.toString().toLowerCase() == 'mechanic') {
      userRole = 'mechanic';
    } else {
      userRole = role.toString().toLowerCase();
    }

    print("🔔 NotificationService Initialized for Role: $userRole");

    // استدعاء دوال التهيئة الأصلية الخاصة بك
    await initializeLocalNotifications();
    await initializeFirebaseMessaging();
    await _startSignalR();
  }

  // --- تهيئة الإشعارات المحلية (Local Notifications) ---
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification clicked: ${response.payload}");
      },
    );

    await _loadNotificationsFromPrefs();
  }

  // --- تهيئة إشعارات فايربيز (Firebase Messaging) للخلفية ---
  Future<void> initializeFirebaseMessaging() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted Firebase messaging permission.');
        
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM Token: $fcmToken");
        if (fcmToken != null && token != null) {
          await _sendTokenToServer(fcmToken);
        }
      }
    } catch (e) {
      print("Error initializing Firebase Messaging: $e");
    }
  }

  // إرسال توكن الفايربيز للسيرفر للإشعارات البعيدة
  Future<void> _sendTokenToServer(String fcmToken) async {
    try {
      await _dio.post(
        "https://gearupapp.runasp.net/api/notifications/save-token",
        data: {"token": fcmToken},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      print("FCM Token Saved to Server successfully.");
    } catch (e) {
      print("Failed to save FCM token to server: $e");
    }
  }

  // 🔥 دالة الـ SignalR مع تعديل قنوات الاستماع لتعمل فوراً والتطبيق مفتوح (Foreground)
  Future<void> _startSignalR() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      return;
    }

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          "https://gearupapp.runasp.net/notificationHub",
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
            transport: HttpTransportType.LongPolling, // مستقر جداً على الموبايل والتطبيق مفتوح ويمنع الفصل
          ),
        )
        .build();

    _hubConnection!.onclose(({error}) => print("SignalR Connection Closed ❌: $error"));

    // 1. الاستماع الديناميكي حسب الـ Role (مثل ReceiveNotification_customer)
    if (userRole != null) {
      final capitalizeRole = userRole![0].toUpperCase() + userRole!.substring(1); // Customer / Mechanic
      
      _hubConnection!.on("ReceiveNotification_$userRole", (arguments) {
        _handleIncomingNotification(arguments);
      });
      
      _hubConnection!.on("ReceiveNotification_$capitalizeRole", (arguments) {
        _handleIncomingNotification(arguments);
      });
    }

    // 2. الاستماع العام (لو السيرفر بيبعت على القناة العامة)
    _hubConnection!.on("ReceiveNotification", (arguments) {
      _handleIncomingNotification(arguments);
    });

    try {
      await _hubConnection!.start();
      print("SignalR Connected to Hub Successfully ✅");
    } catch (e) {
      print("Error starting SignalR: $e");
    }
  }

  // 🔥 دالة معالجة الإشعار القادم ودفع التحديث للجرس والصفحة فوراً زي الويب بالظبط
  void _handleIncomingNotification(List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      print("New Foreground Notification Received: ${arguments.first}");
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(arguments.first as Map);
        
        // ترجمة العناوين والرسائل للحجوزات لتطابق مسميات الويب العربي
        String? finalTitle = json['title'];
        String? finalMessage = json['message'] ?? json['description'];

        if (json['isBooking'] == true && finalTitle != null) {
          if (bookingTitleMap.containsKey(finalTitle)) {
            finalTitle = bookingTitleMap[finalTitle];
          }
          if (bookingMessageMap.containsKey(json['title'])) {
            finalMessage = bookingMessageMap[json['title']];
          }
        }

        final updatedJson = {
          ...json,
          'title': finalTitle,
          'message': finalMessage,
          'time': json['time'] ?? "الآن",
        };

        final item = NotificationItem.fromJson(updatedJson);
        
        // إضافة الإشعار أول القائمة وتحديث الـ UI كاش وفوراً
        notifications.insert(0, item);
        _saveNotificationsToPrefs();
        
        // تشغيل الهز والتحديث اللحظي لجرس التنبيهات
        isShaking = true;
        notifyListeners();
        
        // إظهار التنبيه المنبثق المحلي هيدر الشاشة
        showLocalNotification(
          item.title ?? "تنبيه جديد 🔔", 
          item.message ?? item.description ?? ""
        );
        
        // إيقاف الهز بعد ثانيتين
        Future.delayed(const Duration(seconds: 2), () {
          isShaking = false;
          notifyListeners();
        });
      } catch (e) {
        print("Error parsing incoming notification: $e");
      }
    }
  }

  // إظهار شعار التنبيه (Heads-up Notification) أعلى الشاشة والتطبيق مفتوح
  void showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gearup_notifications',
      'GearUp Alerts',
      channelDescription: 'Notifications for GearUp Application',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  // --- حفظ وجلب البيانات محلياً (SharedPreferences) ---
  Future<void> _saveNotificationsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
        notifications.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('cached_notifications', jsonList);
  }

  Future<void> _loadNotificationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('cached_notifications');
    if (jsonList != null) {
      notifications = jsonList
          .map((str) => NotificationItem.fromJson(jsonDecode(str)))
          .toList();
      notifyListeners();
    }
  }

  void removeNotification(int index) {
    if (index >= 0 && index < notifications.length) {
      notifications.removeAt(index);
      _saveNotificationsToPrefs();
      notifyListeners();
    }
  }

  void clearAll() {
    notifications.clear();
    _saveNotificationsToPrefs();
    notifyListeners();
  }

  // --- API Actions (الـ Handlers الخاصة بلوحة تحكم الميكانيكي) ---
  Future<bool> acceptRequestWithPrice(
    String requestId,
    double price,
    int index,
  ) async {
    try {
      await _dio.post(
        "https://gearupapp.runasp.net/api/mechanic/requests/$requestId/accept",
        data: {"price": price},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      removeNotification(index);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId, int index) async {
    try {
      await _dio.post(
        "https://gearupapp.runasp.net/api/mechanic/requests/$requestId/reject",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      removeNotification(index);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitRating(
    String requestId,
    int stars,
    String comment,
    int index,
  ) async {
    try {
      await _dio.post(
        "https://gearupapp.runasp.net/api/requests/$requestId/rate",
        data: {"stars": stars, "comment": comment},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      removeNotification(index);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _hubConnection?.stop();
    super.dispose();
  }
}