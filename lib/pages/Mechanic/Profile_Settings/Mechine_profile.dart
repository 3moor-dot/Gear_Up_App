import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';

class MachineProfilePage extends StatefulWidget {
  const MachineProfilePage({super.key});

  @override
  State<MachineProfilePage> createState() => _MachineProfilePageState();
}

class _MachineProfilePageState extends State<MachineProfilePage> {
  // الحقول والبيانات
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String email = "";
  String avatarUrl = "";
  File? _selectedImage;

  bool _isLoading = false;
  bool _isSaving = false;
  String _statusMessage = "";
  bool _isError = false;

  final String baseUrl = "https://gearupapp.runasp.net/api";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // جلب البيانات (GET Profile)
  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      final response = await http.get(
        Uri.parse("$baseUrl/users/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstNameController.text = data['firstName'] ?? "";
          _lastNameController.text = data['lastName'] ?? "";
          email = data['email'] ?? "";
          avatarUrl = data['profilePhotoUrl'] ?? "";
        });
      } else {
        setState(() {
          _isError = true;
          _statusMessage = "حدث خطأ أثناء تحميل البيانات";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = "تعذر الاتصال بالخادم";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // حفظ التغييرات (PUT Profile using MultiPart/FormData)
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _statusMessage = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      var request = http.MultipartRequest('PUT', Uri.parse("$baseUrl/users/profile"));
      request.headers.addAll({"Authorization": "Bearer $token"});

      // إضافة الحقول النصية (FormData)
      request.fields['FirstName'] = _firstNameController.text;
      request.fields['LastName'] = _lastNameController.text;
      request.fields['Phone'] = ""; // كما في كود React

      // إضافة الصورة إذا تم اختيارها
      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ProfilePhoto',
          _selectedImage!.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _isError = false;
          _statusMessage = "تم حفظ التغييرات بنجاح ✅";
          _selectedImage = null;
        });
        _fetchProfile(); // تحديث البيانات
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isError = true;
          _statusMessage = errorData['message'] ?? "حدث خطأ أثناء الحفظ";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = "تعذر الاتصال بالخادم";
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // اختيار صورة
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
      endDrawer: const MachineDrawer(currentRoute: '/profile'),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const MachineHeader(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryBlue))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            // رسائل الحالة
                            if (_statusMessage.isNotEmpty) _buildStatusBanner(),
                            const SizedBox(height: 10),
                            _buildTopActions(primaryBlue, isDark),
                            const SizedBox(height: 25),
                            _buildProfileCard(primaryBlue, isDark),
                            const SizedBox(height: 20),
                            _buildDataForm(isDark, primaryBlue),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: _isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isError ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: TextStyle(color: _isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTopActions(Color primaryColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _customButton(
            label: "أكمل ملفك",
            color: const Color(0xFF0BDA65),
            onPressed: () {},
            isOutline: !isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _customButton(
            label: _isSaving ? "جاري الحفظ..." : "حفظ التغييرات",
            color: primaryColor,
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving,
            isOutline: !isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor, width: 2)),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null) as ImageProvider?,
                  child: avatarUrl.isEmpty && _selectedImage == null ? Icon(Icons.person, size: 50, color: primaryColor) : null,
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text("${_firstNameController.text} ${_lastNameController.text}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(email, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 13)),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("📷 صورة مختارة جديدة", style: TextStyle(color: primaryColor, fontSize: 11)),
            ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF0BDA65).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text("مفعل", style: TextStyle(color: Color(0xFF0BDA65), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDataForm(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("البيانات الشخصية", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.blueGrey[800])),
          const SizedBox(height: 20),
          _buildTextField("الاسم الأول", _firstNameController, isDark, primaryColor),
          const SizedBox(height: 16),
          _buildTextField("الاسم الآخر", _lastNameController, isDark, primaryColor),
          const SizedBox(height: 16),
          _buildTextField("البريد الإلكتروني", TextEditingController(text: email), isDark, primaryColor, readOnly: true),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                foregroundColor: isDark ? Colors.white : Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("تغيير كلمة المرور", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, Color primaryColor, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.black26 : Colors.white,
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryColor, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryColor.withOpacity(0.1))),
          ),
        ),
      ],
    );
  }

  Widget _customButton({required String label, required Color color, required VoidCallback? onPressed, bool isOutline = false, bool isLoading = false}) {
    return Container(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutline ? color.withOpacity(0.15) : color,
          foregroundColor: isOutline ? color : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}