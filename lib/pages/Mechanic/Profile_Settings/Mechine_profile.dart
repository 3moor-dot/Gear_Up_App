import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
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
  String avatarUrl = "https://via.placeholder.com/150";
  File? _selectedImage;

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // محاكاة جلب البيانات من الـ API
  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      // هنا تضع كود الـ http.get الخاص بك
      await Future.delayed(const Duration(seconds: 1)); // محاكاة وقت التحميل
      
      setState(() {
        _firstNameController.text = "أحمد";
        _lastNameController.text = "محمد";
        email = "mechanic@gearup.com";
        avatarUrl = "https://i.pravatar.cc/300";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // اختيار صورة من المعرض
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // حفظ التغييرات
  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    // محاكاة طلب PUT
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSaving = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حفظ التغييرات بنجاح ✅"), backgroundColor: Colors.green),
    );
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTopActions(primaryBlue, isDark),
                          const SizedBox(height: 30),
                          _buildProfileCard(primaryBlue, isDark),
                          const SizedBox(height: 20),
                          _buildDataForm(isDark),
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

  // أزرار الحفظ والإكمال
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
          ),
        ),
      ],
    );
  }

  // كارت الصورة والمعلومات الأساسية
  Widget _buildProfileCard(Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _selectedImage != null 
                    ? FileImage(_selectedImage!) 
                    : NetworkImage(avatarUrl) as ImageProvider,
              ),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${_firstNameController.text} ${_lastNameController.text}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Chip(
            label: const Text("مفعل"),
            backgroundColor: const Color(0xFF0BDA65).withOpacity(0.2),
            labelStyle: const TextStyle(color: Color(0xFF0BDA65), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // فورم البيانات الشخصية
  Widget _buildDataForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC).withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("البيانات الشخصية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField("الاسم الأول", _firstNameController, isDark),
          const SizedBox(height: 16),
          _buildTextField("الاسم الأخير", _lastNameController, isDark),
          const SizedBox(height: 16),
          _buildTextField("البريد الإلكتروني", TextEditingController(text: email), isDark, readOnly: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("تغيير كلمة المرور", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey : (isDark ? Colors.white : Colors.black)),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.black26 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _customButton({required String label, required Color color, required VoidCallback? onPressed, bool isOutline = false, bool isLoading = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutline ? color.withOpacity(0.2) : color,
        foregroundColor: isOutline ? color : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading 
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}