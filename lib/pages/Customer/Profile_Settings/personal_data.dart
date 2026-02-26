import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalDataTab extends StatefulWidget {
  const PersonalDataTab({super.key});

  @override
  State<PersonalDataTab> createState() => _PersonalDataTabState();
}

class _PersonalDataTabState extends State<PersonalDataTab> {
  // الحالات (States)
  bool isEditable = false;
  bool loading = false;
  
  // Controllers للمدخلات
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? email; // للعرض فقط كما في React
  String? profilePhotoUrl;

  File? _selectedImage; // للصورة المختارة محلياً
  final primaryColor = const Color(0xFF137FEC);

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // جلب البيانات (GET Profile)
  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');

    try {
      final response = await http.get(
        Uri.parse("http://gearupapp.runasp.net/api/users/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstNameController.text = data['firstName'] ?? "";
          _lastNameController.text = data['lastName'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          email = data['email'] ?? "";
          profilePhotoUrl = data['profilePhotoUrl'];
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب البيانات: $e");
    }
  }

  // اختيار صورة من المعرض
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // حفظ التغييرات (PUT Profile)
  Future<void> handleSave() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("http://gearupapp.runasp.net/api/users/profile"),
      );

      request.headers['Authorization'] = "Bearer $token";
      
      // إضافة الحقول النصية
      request.fields['FirstName'] = _firstNameController.text;
      request.fields['LastName'] = _lastNameController.text;
      request.fields['Phone'] = _phoneController.text;

      // إضافة الصورة إذا تم اختيار واحدة جديدة
      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ProfilePhoto', 
          _selectedImage!.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar("تم تحديث البيانات بنجاح", Colors.green);
        setState(() => isEditable = false);
        fetchProfile();
      } else {
        _showSnackBar("حدث خطأ أثناء الحفظ", Colors.red);
      }
    } catch (e) {
      _showSnackBar("فشل الاتصال بالسيرفر", Colors.red);
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1F2D) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: primaryColor.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Column(
            children: [
              // الهيدر: العنوان + زر التعديل
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("البيانات الشخصية الأساسية", 
                    style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w900)),
                  if (!isEditable)
                    TextButton.icon(
                      onPressed: () => setState(() => isEditable = true),
                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                      label: const Text("تعديل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(backgroundColor: Colors.amber[700], shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    ),
                ],
              ),
              const Divider(height: 40),

              // قسم الصورة
              _buildImageSection(),
              const SizedBox(height: 30),

              // المدخلات
              Row(
                children: [
                  Expanded(child: _buildInputField("الاسم الأول", _firstNameController, isEditable)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField("اسم العائلة", _lastNameController, isEditable)),
                ],
              ),
              const SizedBox(height: 15),
              _buildInputField("رقم الهاتف", _phoneController, isEditable),
              const SizedBox(height: 15),
              
              // البريد الإلكتروني (للعرض فقط)
              _buildReadOnlyField("البريد الإلكتروني (للعرض فقط)", email ?? "..."),

              const SizedBox(height: 40),

              // أزرار الحفظ والإلغاء
              if (isEditable)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        loading ? "جاري الحفظ..." : "حفظ التغييرات", 
                        primaryColor, 
                        handleSave,
                        icon: Icons.save
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        "إلغاء", 
                        const Color(0xFF2D3342), 
                        () {
                          setState(() {
                            isEditable = false;
                            _selectedImage = null;
                            fetchProfile();
                          });
                        }
                      )
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.1), width: 4),
                image: DecorationImage(
                  image: _selectedImage != null 
                    ? FileImage(_selectedImage!) 
                    : (profilePhotoUrl != null 
                        ? NetworkImage(profilePhotoUrl!) 
                        : const NetworkImage("https://ui-avatars.com/api/?name=User")) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (isEditable)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 20,
                    child: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Text("الصورة الشخصية", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Text(label, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.transparent : Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: enabled ? BorderSide(color: primaryColor.withOpacity(0.3)) : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: const Text("البريد الإلكتروني (للعرض فقط)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(value, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap, {IconData? icon}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: Colors.white, size: 20),
          if (icon != null) const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}