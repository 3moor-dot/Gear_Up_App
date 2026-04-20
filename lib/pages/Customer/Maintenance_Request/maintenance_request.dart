import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Request/request_tracking_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  const MaintenanceRequestScreen({super.key});

  @override
  State<MaintenanceRequestScreen> createState() =>
      _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen> {
  // --- الألوان والحالة العامة ---
  final Color primaryColor = const Color(0xFF137FEC);
  final ScrollController _scrollController = ScrollController();
  Timer? _countdownTimer; // عداد الدائرة
  Timer? _pollingTimer; // فحص السيرفر
  int _currentStep = 1;
  bool _isLoading = false;
  List<dynamic> _cars = [];
  String? _selectedCarId;
  VoidCallback? _onTimerTick;
  bool _isPermissionRequesting = false;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late int _timeLeft = 300; // 5 دقائق
  final String _searchPhase = "waiting"; // waiting, expanding, timeout
  // بيانات النموذج
  final TextEditingController _issueController = TextEditingController();
  File? _selectedImage;
  int _requestType = 1;
  int? _serviceType;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  String? _requestId;
  final String _darkMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1d2c4d"}]
  }
]''';
  late List<dynamic> _acceptedMechanics = [];
  final List<Map<String, dynamic>> _serviceTypes = [
    {"id": 1, "title": "تشخيص", "icon": "🛠️"},
    {"id": 2, "title": "إطارات", "icon": "🛞"},
    {"id": 3, "title": "سمكرة", "icon": "🔨"},
    {"id": 4, "title": "زيوت", "icon": "🛢️"},
  ];
  int _serviceMode = 2;
  VoidCallback? _onMechanicsUpdated;

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // --- API Methods (نفس المنطق السابق) ---
  Future<void> _fetchCars() async {
    try {
      // 1. جلب التوكن المحفوظ من ذاكرة الهاتف
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('userToken');

      if (token == null || token.isEmpty) {
        debugPrint("No token found!");
        return;
      }

      // 2. إرسال الطلب بالتوكن الحقيقي
      final response = await http.get(
        Uri.parse("https://gearupapp.runasp.net/api/requests/cars"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // تأكد من شكل البيانات الراجع من السيرفر (Data mapping)
        // إذا كان السيرفر يرسل قائمة مباشرة استخدم data بدلاً من data['cars']
        setState(() {
          if (data is Map && data.containsKey('cars')) {
            _cars = data['cars'];
          } else if (data is List) {
            _cars = data;
          }
          if (_cars.isNotEmpty) {
            _selectedCarId = _cars[0]['id'].toString();
          }
        });
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching cars: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // السايد بار (Drawer)
      endDrawer: const CustomDrawer(currentRoute: '/customer/request'),
      backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(), // الهيدر الثابت
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _currentStep == 1
                      ? _buildStepOne(isDark)
                      : _buildStepTwo(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- واجهة الخطوة الأولى (إدخال البيانات) ---
  Widget _buildStepOne(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "طلب صيانة جديد",
          "قم بتعبئة البيانات لإرسال طلبك للميكانيكيين.",
          isDark,
        ),
        const SizedBox(height: 25),

        _titleWithUnderline("اختر مركبة", primaryColor),
        const SizedBox(height: 15),
        _buildCarDropdown(isDark),
        const SizedBox(height: 25),

        _titleWithUnderline("نوع الخدمة", primaryColor),

        const SizedBox(height: 15),
        Row(
          children: [
            _selectionCard(
              "🚨 طارئة",
              "إصلاح في الحال",
              _requestType == 1,
              () => setState(() => _requestType = 1),
              isDark,
            ),
            const SizedBox(width: 15),
            _selectionCard(
              "📅 مجدولة",
              "حجز موعد لاحق",
              _requestType == 2,
              () => setState(() => _requestType = 2),
              isDark,
            ),
          ],
        ),
        if (_requestType == 1) ...[
          const SizedBox(height: 25),

          _titleWithUnderline("أين الميكانيكي؟", primaryColor),
          const SizedBox(height: 15),

          Row(
            children: [
              _selectionCard(
                "في الورشة",
                "",
                _serviceMode == 2,
                () => setState(() => _serviceMode = 2),
                isDark,
              ),
              const SizedBox(width: 15),
              _selectionCard(
                "متنقل إليك",
                "",
                _serviceMode == 1,
                () => setState(() => _serviceMode = 1),
                isDark,
              ),
            ],
          ),
        ],
        // الجزء الخاص بالتاريخ والوقت يظهر فقط في "مجدولة"
        if (_requestType == 2) ...[
          const SizedBox(height: 25),
          _titleWithUnderline("موعد الصيانة", primaryColor),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration("اختر التاريخ", isDark).copyWith(
                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  decoration: _inputDecoration("اختر الوقت", isDark).copyWith(
                    prefixIcon: const Icon(Icons.access_time, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 25),

        _titleWithUnderline("تحديد الموقع", primaryColor),
        const SizedBox(height: 15),
        _buildGoogleMap(isDark),
        const SizedBox(height: 25),

        _titleWithUnderline("تفاصيل العطل", primaryColor),
        const SizedBox(height: 15),
        TextField(
          controller: _issueController,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          textAlign: TextAlign.right,
          decoration: _inputDecoration("اكتب وصفاً للمشكلة هنا...", isDark),
        ),
        const SizedBox(height: 15),
        _buildImagePicker(isDark),

        const SizedBox(height: 40),
        _titleWithUnderline("تصنيف العطل", primaryColor),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _serviceTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 👈 هنا السر (4 في الصف)
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9, // يخلي الكارت أطول شوية
          ),
          itemBuilder: (context, index) {
            final item = _serviceTypes[index];
            final isSelected = _serviceType == item['id'];

            return GestureDetector(
              onTap: () => setState(() => _serviceType = item['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['icon'],
                      style: const TextStyle(
                        fontSize: 22,
                      ), // 👈 أصغر عشان المساحة
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10, // 👈 مهم جداً
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        _buildSubmitButton(isDark),
        const SizedBox(height: 100), // مساحة إضافية للسكرول
      ],
    );
  }

  Widget _buildGoogleMap(bool isDark) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: _currentLocation == null
            ? InkWell(
                onTap: _getCurrentLocation,
                child: Center(
                  child: Text(
                    "اضغط لتحديد موقعك",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              )
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller; // 👈 أهم سطر

                  if (isDark && _mapController != null) {
                    _mapController!.setMapStyle(_darkMapStyle);
                  }
                },
                markers: _markers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
              ),
      ),
    );
  }

  bool get _isStepOneValid {
    return _selectedCarId != null &&
        _issueController.text.trim().isNotEmpty &&
        _currentLocation != null &&
        (_requestType == 1 || (_selectedDate != null && _selectedTime != null));
  }

  // --- واجهة الخطوة الثانية (الميكانيكيين) ---
  Widget _buildStepTwo(bool isDark) {
    return Column(
      children: [
        _buildSectionHeader(
          "الميكانيكيين المتاحين",
          "اختر الميكانيكي المناسب لبدء العمل.",
          isDark,
        ),
        const SizedBox(height: 30),
        if (_acceptedMechanics.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 20),
                const Text("في انتظار قبول طلبك من الميكانيكيين..."),
              ],
            ),
          )
        else
          ..._acceptedMechanics.map((m) => _buildMechanicCard(m, isDark)),

        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () => setState(() => _currentStep = 1),
          icon: const Icon(Icons.arrow_back),
          label: const Text("الرجوع لتعديل البيانات"),
        ),
      ],
    );
  }

  // --- مساعدات التصميم (UI Helpers) ---

  Widget _buildSectionHeader(String title, String subTitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(subTitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  Widget _titleWithUnderline(String title, Color color) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.5), width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildCarDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCarId,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: _cars
              .map(
                (car) => DropdownMenuItem(
                  value: car['id'].toString(),
                  child: Text(
                    "${car['brand']} ${car['model']}",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedCarId = val),
        ),
      ),
    );
  }

  Widget _selectionCard(
    String title,
    String sub,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF1E293B) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (img != null) setState(() => _selectedImage = File(img.path));
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(Icons.image, color: primaryColor),
            const SizedBox(width: 10),
            const Text("إرفاق صورة العطل (اختياري)"),
            const Spacer(),

            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                width: 50,
                height: 40,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: (_isLoading || !_isStepOneValid) ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isStepOneValid ? primaryColor : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "إرسال طلب الصيانة",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1E293B)
          : Colors.grey[50]?.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (_isPermissionRequesting) return;

    setState(() => _isPermissionRequesting = true);
    if (_currentLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // ✅ 1. حاول تجيب آخر موقع فوراً (سريع جداً)
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        setState(() {
          _currentLocation = LatLng(
            lastPosition.latitude,
            lastPosition.longitude,
          );
        });

        await _getNearbyPlaces();
      }

      // ✅ 2. في الخلفية هات موقع أحدث (بدون ما يهنج UI)
      Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          )
          .then((position) {
            if (!mounted) return;

            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          })
          .catchError((e) {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تعذر تحديد الموقع")));
    } finally {
      setState(() => _isPermissionRequesting = false);
    }
  }

  Future<void> _getNearbyPlaces() async {
    if (_currentLocation == null) return;

    final apiKey = "YOUR_API_KEY"; // 👈 حط المفتاح هنا

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=${_currentLocation!.latitude},${_currentLocation!.longitude}"
      "&radius=3000"
      "&type=car_repair"
      "&key=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final results = data['results'];

    Set<Marker> markers = {};

    // 📍 موقعك
    markers.add(
      Marker(
        markerId: const MarkerId("me"),
        position: LatLng(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // 🔧 الميكانيكيين
    for (var place in results) {
      final lat = place['geometry']['location']['lat'];
      final lng = place['geometry']['location']['lng'];

      markers.add(
        Marker(
          markerId: MarkerId(place['place_id']),
          position: LatLng(lat, lng),
          onTap: () => _showPlaceDetails(place),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showPlaceDetails(dynamic place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  Text(
                    place['name'] ?? "ميكانيكي",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  Text("⭐ ${place['rating'] ?? 'بدون تقييم'}"),

                  SizedBox(height: 10),

                  Text(place['vicinity'] ?? ""),

                  Text("خدمة إصلاح سيارات قريبة منك"),
                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {},
                    child: Text("اختيار هذا الميكانيكي"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMechanicsSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            _onTimerTick = () => setSheetState(() {});

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.85,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B1220) // نفس خلفية الدارك
                        : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: _buildSearchingUI(isDark), // 👈 ابعت isDark
                );
              },
            );
          },
        );
      },
    );
  }

  // واجهة البحث (نفس شكل الدائرة في رياكت)
  Widget _buildSearchingUI(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 15),

        // خط السحب الصغير
        Container(
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 30),

        Text(
          "جاري البحث عن ميكانيكي قريب",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "سيتم إشعارك فور قبول أحد الميكانيكيين",
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
        ),
        const SizedBox(height: 40),

        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: _timeLeft / 300,
                strokeWidth: 10,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF137FEC)),
              ),
            ),
            Column(
              children: [
                Text(
                  "${(_timeLeft ~/ 60)}:${(_timeLeft % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF137FEC),
                  ),
                ),
                const Text("وقت الانتظار"),
              ],
            ),
          ],
        ),

        const SizedBox(height: 30),

        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            _countdownTimer?.cancel();
            _pollingTimer?.cancel();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          label: const Text("إلغاء الطلب"),
        ),
      ],
    );
  }

  // --- دالة اختيار التاريخ ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  // --- دالة اختيار الوقت المعدلة ---
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;

        // تحويل الوقت لصيغة 24 ساعة لكي يقبله السيرفر (مثلاً 18:30 بدلاً من 6:30 م)
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');

        // هذا النص هو ما سيظهر للمستخدم وهو ما سيرسل للسيرفر
        _timeController.text = "$hour:$minute";
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_isStepOneValid) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      var uri = Uri.parse("https://gearupapp.runasp.net/api/requests");
      var request = http.MultipartRequest("POST", uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json', // 👈 مهم
      });

      request.fields.addAll({
        'carId': _selectedCarId!,
        'issueDescription': _issueController.text,
        'requestType': _requestType.toString(),
        'serviceMode': _serviceMode.toString(),
        'serviceType': (_serviceType ?? 1).toString(),
        'latitude': _currentLocation!.latitude.toString(),
        'longitude': _currentLocation!.longitude.toString(),
      });

      if (_requestType == 2) {
        // التأكد من إرسال التاريخ والوقت بصيغة YYYY-MM-DD و HH:mm
        request.fields['scheduledDate'] =
            "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

        request.fields['scheduledTime'] =
            _timeController.text; // التي أصبحت الآن بنظام 24 ساعة
      }
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'problemPhoto',
            _selectedImage!.path,
          ), // تغيير image إلى ProblemPhoto
        );
      }
      debugPrint("➡️ POST: $uri");
      debugPrint("📦 Fields: ${request.fields}");
      debugPrint("📸 Has Image: ${_selectedImage != null}");
      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final respStr = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(respStr);
        _requestId = data['requestId']?.toString() ?? data['id']?.toString();

        _timeLeft = 300;

        _countdownTimer?.cancel();

        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;

          if (_timeLeft > 0) {
            _timeLeft--;

            // تحديث الصفحة الرئيسية
            setState(() {});

            // 🔥🔥🔥 تحديث الـ BottomSheet (ده كان ناقص)
            _onTimerTick?.call();
          } else {
            timer.cancel();
          }
        });

        _showMechanicsSelectionSheet();
        _startPolling(); // لبدء فحص الميكانيكيين كل 5 ثواني
      } else {
        final errorData = json.decode(respStr);
        debugPrint("❌ ERROR RESPONSE: $errorData");
        throw Exception(errorData.toString());
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل إرسال الطلب")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForAcceptedMechanics();
    });
  }

  Future<void> _checkForAcceptedMechanics() async {
    if (_requestId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null) return;

    final response = await http.get(
      Uri.parse(
        "https://gearupapp.runasp.net/api/requests/$_requestId/accepted-mechanics",
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> mechanicsList = (data is List)
          ? data
          : (data['mechanics'] ?? []);

      if (mechanicsList.isNotEmpty) {
        // 1. إيقاف العدادات والبحث
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();

        setState(() {
          _acceptedMechanics = mechanicsList;
        });

        // 2. إظهار الميكانيكيين من أسفل الشاشة
        _showMechanicsBottomSheet();
      }
    }
  }

  void _showMechanicsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "الميكانيكيون الذين وافقوا",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _acceptedMechanics.length,
                itemBuilder: (context, index) {
                  final mech = _acceptedMechanics[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        mech['profilePhotoUrl'] ?? '',
                      ),
                    ),
                    title: Text("${mech['firstName']} ${mech['lastName']}"),
                    subtitle: Text("⭐ ${mech['averageRating'] ?? '5'}"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // إغلاق التبويب
                        _handleSelectMechanic(
                          mech['mechanicUserId'],
                        ); // استدعاء دالة الاختيار
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text(
                        "اختيار",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة اختيار الميكانيكي والتحويل لصفحة التتبع
  Future<void> _handleSelectMechanic(String mechanicUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.post(
        Uri.parse(
          "https://gearupapp.runasp.net/api/requests/$_requestId/select-mechanic/$mechanicUserId",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          // ✅ الانتقال الصحيح وتمرير الـ ID الفعلي
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RequestTrackingScreen(requestId: _requestId!),
            ),
          );
        }
      } else {
        print("Error From Server: ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  Widget _buildMechanicCard(dynamic m, bool isDark) {
    return Container(); // يمكنك بناء كارت الميكانيكي هنا
  }
}
