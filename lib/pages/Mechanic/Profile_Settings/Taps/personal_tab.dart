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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // الحصول على التوكن
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  // ======= جلب البيانات (FETCH) =======
  Future<void> _fetchProfile() async {
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
        setState(() {
          _firstNameController.text = json['firstName'] ?? "";
          _lastNameController.text = json['lastName'] ?? "";
          _phoneController.text = json['phone'] ?? "";
          _email = json['email'] ?? "";
          _profilePhotoUrl = json['profilePhotoUrl'];
        });
      } else {
        setState(() => _errorMessage = "فشل في تحميل البيانات");
      }
    } catch (e) {
      setState(() => _errorMessage = "حدث خطأ في الاتصال بالخادم");
    } finally {
      setState(() => _isLoading = false);
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

      // Fields (نفس مسميات الـ FormData في React)
      request.fields['FirstName'] = _firstNameController.text;
      request.fields['LastName'] = _lastNameController.text;
      request.fields['Phone'] = _phoneController.text;

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
        setState(() {
          _successMessage = "تم حفظ التغييرات بنجاح ✅";
          _isEditing = false;
          _selectedImage = null;
        });
        _fetchProfile(); // إعادة جلب البيانات لتحديث العرض
      } else {
        final errorJson = jsonDecode(response.body);
        setState(() => _errorMessage = errorJson['message'] ?? "فشل الحفظ");
      }
    } catch (e) {
      setState(() => _errorMessage = "تعذر الاتصال بالخادم");
    } finally {
      setState(() => _isSaving = false);
    }
  }

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

    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(50.0), child: CircularProgressIndicator()));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: isDark ? Colors.blue.withOpacity(0.1) : Colors.grey[200]!),
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
          _buildField("البريد الإلكتروني", TextEditingController(text: _email), Icons.email, isDark, enabled: false),

          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, padding: const EdgeInsets.all(14)),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("حفظ التغييرات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text("إلغاء"),
                )
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(String msg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 13)),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("البيانات الأساسية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (!_isEditing)
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: Icon(Icons.edit, size: 18, color: color),
            label: Text("تعديل", style: TextStyle(color: color)),
          ),
      ],
    );
  }

  Widget _buildAvatarSection(Color color) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey[200],
              backgroundImage: _selectedImage != null 
                  ? FileImage(_selectedImage!) 
                  : (_profilePhotoUrl != null 
                      ? NetworkImage(_profilePhotoUrl!) 
                      : const NetworkImage("https://via.placeholder.com/150")) as ImageProvider,
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
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: isActuallyEnabled,
            keyboardType: type,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 15, color: isActuallyEnabled ? (isDark ? Colors.white : Colors.black) : Colors.grey),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: isActuallyEnabled ? Colors.blue : Colors.grey),
              filled: true,
              fillColor: isActuallyEnabled ? (isDark ? Colors.white.withOpacity(0.05) : Colors.blue.withOpacity(0.02)) : (isDark ? Colors.black12 : Colors.grey[100]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
            ),
          ),
        ],
      ),
    );
  }
}