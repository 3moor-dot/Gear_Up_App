import 'package:flutter/material.dart';
import 'package:gear_up_app/pages/Notification/notification_model.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1323) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF151C33) : Colors.white,
        elevation: 0,
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final list = notificationService.notifications;

          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات حالياً',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = list[index];
              
              // 🔥 تجهيز نص الإشعار بالتفاصيل الكاملة زي الويب بالظبط
              String displayMessage = item.message ?? item.description ?? '';
              
              if (item.isBooking) {
                final customer = item.customerName ?? 'عميل';
                final service = item.serviceCategory ?? 'صيانة';
                final date = item.date ?? '';
                final timeSlot = (item.slotStart != null && item.slotEnd != null) 
                    ? 'من ${item.slotStart} إلى ${item.slotEnd}' 
                    : '';
                
                displayMessage = 'العميل: $customer\nالخدمة: $service\nالموعد: $date $timeSlot'.trim();
              } else if (item.isRequest && item.requestDetail != null) {
                displayMessage = '${item.message ?? ""}\nالتفاصيل: ${item.requestDetail}'.trim();
              }

              return Dismissible(
                key: Key('${item.requestId}_${item.bookingId}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) {
                  notificationService.removeNotification(index);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  // تحديد الحواف والإطار هنا بالطريقة الصح في فلاتر لمنع الأيرور 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  color: isDark ? const Color(0xFF151C33) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // أيقونة الإشعار الجانبية
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getIconColor(item).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(item), color: _getIconColor(item), size: 26),
                        ),
                        const SizedBox(width: 15),
                        
                        // محتوى النصوص والتفاصيل كاملة
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.title ?? 'تنبيه جديد',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    item.time ?? 'الآن',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayMessage,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              
                              // إضافة كارت السيارة واللوحة في الأسفل لو كان متوفراً
                              if (item.carName != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '🚗 ${item.carName} (${item.plateNumber ?? ""})',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(NotificationItem item) {
    if (item.isRequest) return Icons.build_circle_outlined;
    if (item.isBooking) return Icons.calendar_month_outlined;
    return Icons.notifications_active_outlined;
  }

  Color _getIconColor(NotificationItem item) {
    if (item.isRequest) return Colors.orange;
    if (item.isBooking) return Colors.green;
    return const Color(0xFF137FEC);
  }
}