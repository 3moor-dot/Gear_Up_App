// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PersonalTab extends StatefulWidget {
  const PersonalTab({super.key});

  @override
  State<PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // تم الإصلاح: تعريف الكنترولر هنا بدلاً من دالة الـ build
  
  String _email = "";
  String? _profilePhotoUrl;
  File? _selectedImage;

  // States
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = "";
  String _successMessage = "";

  final String _baseUrl = "https://gearupapp.runasp.net/api";
  final Color primaryBlue = const Color(0xFF137FEC);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // الحصول على التوكن
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  // ======= جلب البيانات (FETCH) =======
  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse("$_baseUrl/users/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _firstNameController.text = json['firstName'] ?? "";
            _lastNameController.text = json['lastName'] ?? "";
            _phoneController.text = json['phone'] ?? "";
            _email = json['email'] ?? "";
            _emailController.text = _email; // تحديث الكنترولر بالقيمة الجديدة
            _profilePhotoUrl = json['profilePhotoUrl'];
          });
        }
      } else {
        if (mounted) setState(() => _errorMessage = "فشل في تحميل البيانات");
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "حدث خطأ في الاتصال بالخادم");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ======= حفظ البيانات (SAVE - Multipart) =======
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = "";
      _successMessage = "";
    });

    try {
      final token = await _getToken();
      var request = http.MultipartRequest('PUT', Uri.parse("$_baseUrl/users/profile"));
      
      // Headers
      request.headers.addAll({"Authorization": "Bearer $token"});

      // Fields
      request.fields['FirstName'] = _firstNameController.text.trim();
      request.fields['LastName'] = _lastNameController.text.trim();
      request.fields['Phone'] = _phoneController.text.trim();

      // Photo
      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ProfilePhoto',
          _selectedImage!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _successMessage = "تم حفظ التغييرات بنجاح ✅";
            _isEditing = false;
            _selectedImage = null;
          });
        }
        _fetchProfile(); // إعادة جلب البيانات لتحديث العرض والشريط العلوي للتطبيق
      } else {
        // حماية الشاشة من الكراش في حال لم يرجع السيرفر ملف JSON صريح
        try {
          final errorJson = jsonDecode(response.body);
          if (mounted) setState(() => _errorMessage = errorJson['message'] ?? "فشل الحفظ");
        } catch (_) {
          if (mounted) setState(() => _errorMessage = "حدث خطأ غير متوقع في السيرفر");
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "تعذر الاتصال بالخادم");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // تم التعديل: استخدام SingleChildScrollView لمنع مشاكل ظهور لوحة الفاتيح (Keyboard Overflow)
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 24), // مسافة أمان سفلية للكارد
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C2F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(primaryBlue),
            const Divider(height: 32),
            
            // Messages
            if (_successMessage.isNotEmpty) _buildMessage(_successMessage, Colors.green),
            if (_errorMessage.isNotEmpty) _buildMessage(_errorMessage, Colors.red),

            _buildAvatarSection(primaryBlue),
            const SizedBox(height: 32),
            
            _buildField("الاسم الأول", _firstNameController, Icons.person, isDark),
            _buildField("الاسم الأخير", _lastNameController, Icons.person_outline, isDark),
            _buildField("رقم الهاتف", _phoneController, Icons.phone, isDark, type: TextInputType.phone),
            _buildField("البريد الإلكتروني", _emailController, Icons.email, isDark, enabled: false),

            const SizedBox(height: 8),

            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("حفظ التغييرات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isSaving ? null : () {
                      setState(() {
                        _isEditing = false;
                        _selectedImage = null;
                        _errorMessage = "";
                        _successMessage = "";
                      });
                      _fetchProfile(); // تصفير التغييرات وإعادة المزامنة
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text("إلغاء"),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String msg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "البيانات الأساسية", 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        if (!_isEditing)
          ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("تعديل", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildAvatarSection(Color color) {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profilePhotoUrl!);
    } else {
      imageProvider = const NetworkImage("https://via.placeholder.com/150");
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              border: Border.all(color: color.withOpacity(0.2), width: 3),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageProvider,
            ),
          ),
          if (_isEditing)
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool isDark, {bool enabled = true, TextInputType type = TextInputType.text}) {
    bool isActuallyEnabled = _isEditing && enabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.blueGrey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: isActuallyEnabled,
            keyboardType: type,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 15, color: isActuallyEnabled ? (isDark ? Colors.white : Colors.black) : Colors.grey),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: isActuallyEnabled ? primaryBlue : Colors.grey),
              filled: true,
              fillColor: isActuallyEnabled 
                  ? (isDark ? Colors.white.withOpacity(0.02) : Colors.blue.withOpacity(0.01)) 
                  : (isDark ? const Color(0xFF0D1629) : Colors.grey[100]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}