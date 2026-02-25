import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PersonalTab extends StatefulWidget {
  const PersonalTab({super.key});

  @override
  State<PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String email = "example@mail.com";
  String? profilePhotoUrl;
  File? _selectedImage;
  
  bool isEditing = false;
  bool isSaving = false;

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.blue.withOpacity(0.1) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(primaryBlue),
          const Divider(height: 32),
          _buildAvatarSection(primaryBlue),
          const SizedBox(height: 24),
          _buildField("الاسم الأول", _firstNameController, Icons.person, isDark),
          _buildField("الاسم الأخير", _lastNameController, Icons.person_outline, isDark),
          _buildField("رقم الهاتف", _phoneController, Icons.phone, isDark, type: TextInputType.phone),
          _buildField("البريد الإلكتروني", TextEditingController(text: email), Icons.email, isDark, enabled: false),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("البيانات الأساسية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: () => setState(() => isEditing = !isEditing),
          icon: Icon(isEditing ? Icons.close : Icons.edit, color: color),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(Color color) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _selectedImage != null 
                ? FileImage(_selectedImage!) 
                : const NetworkImage("https://i.pravatar.cc/150") as ImageProvider,
          ),
          if (isEditing)
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: isEditing && enabled,
            keyboardType: type,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}