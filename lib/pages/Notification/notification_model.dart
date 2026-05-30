class NotificationItem {
  final String? title;
  final String? message;
  final String? description;
  final String? time;
  final dynamic reminderId;
  final String? carId;
  final String? carName;
  final String? plateNumber;
  final bool isRequest;
  final bool isBooking;
  final bool isSelected;
  final String? requestId;
  final bool hasTracking;
  final String? requestDetail;
  final String? scheduledDateTime;
  final String? status;
  final Map<String, double>? location;
  final String? problemPhotoUrl;
  final String? serviceCategory;
  final String? bookingId;
  final String? customerName;
  final String? mechanicName;
  final String? date;
  final String? slotStart;
  final String? slotEnd;

  NotificationItem({
    this.title, this.message, this.description, this.time, this.reminderId,
    this.carId, this.carName, this.plateNumber,
    this.isRequest = false, this.isBooking = false, this.isSelected = false,
    this.requestId, this.hasTracking = false, this.requestDetail,
    this.scheduledDateTime, this.status, this.location, this.problemPhotoUrl,
    this.serviceCategory, this.bookingId, this.customerName, this.mechanicName,
    this.date, this.slotStart, this.slotEnd,
  });

  // تحويل من JSON لقراءة البيانات من Local Storage أو SignalR
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'],
      message: json['message'],
      description: json['description'],
      time: json['time'],
      reminderId: json['reminderId'],
      carId: json['carId'],
      carName: json['carName'],
      plateNumber: json['plateNumber'],
      isRequest: json['isRequest'] ?? false,
      isBooking: json['isBooking'] ?? false,
      isSelected: json['isSelected'] ?? false,
      requestId: json['requestId'],
      hasTracking: json['hasTracking'] ?? false,
      requestDetail: json['requestDetail'],
      scheduledDateTime: json['scheduledDateTime'],
      status: json['status'],
      location: json['location'] != null ? {
        'lat': (json['location']['lat'] as num).toDouble(),
        'lng': (json['location']['lng'] as num).toDouble(),
      } : null,
      problemPhotoUrl: json['problemPhotoUrl'],
      serviceCategory: json['serviceCategory'],
      bookingId: json['bookingId'],
      customerName: json['customerName'],
      mechanicName: json['mechanicName'],
      date: json['date'],
      slotStart: json['slotStart'],
      slotEnd: json['slotEnd'],
    );
  }

  // تحويل لـ JSON عشان الحفظ في الـ SharedPreferences
  Map<String, dynamic> toJson() => {
    'title': title, 'message': message, 'description': description, 'time': time,
    'reminderId': reminderId, 'carId': carId, 'carName': carName, 'plateNumber': plateNumber,
    'isRequest': isRequest, 'isBooking': isBooking, 'isSelected': isSelected,
    'requestId': requestId, 'hasTracking': hasTracking, 'requestDetail': requestDetail,
    'scheduledDateTime': scheduledDateTime, 'status': status, 'location': location,
    'problemPhotoUrl': problemPhotoUrl, 'serviceCategory': serviceCategory,
    'bookingId': bookingId, 'customerName': customerName, 'mechanicName': mechanicName,
    'date': date, 'slotStart': slotStart, 'slotEnd': slotEnd,
  };
}