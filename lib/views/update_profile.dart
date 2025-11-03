import 'dart:io';
import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  final TextEditingController _currentPasswordController = TextEditingController();

  bool _loading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _addressController = TextEditingController(text: user.address);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // 1️⃣ Update email if changed
      if (_emailController.text != userProvider.email) {
        if (_currentPasswordController.text.isEmpty) {
          throw "Please enter current password to change email.";
        }

        final res = await AuthService().updateEmail(
          newEmail: _emailController.text,
          currentPassword: _currentPasswordController.text,
        );

        if (!res.contains("successfully")) throw res;

        // Update provider email immediately
        userProvider.updateUserData({"email": _emailController.text});
      }

      // 2️⃣ Upload profile image if selected
      String? profileImageUrl;
      if (_selectedImage != null) {
        profileImageUrl = await DbService().uploadProfileImage(_selectedImage!);
      }

      // 3️⃣ Update user fields in Firestore
      final data = {
        "name": _nameController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        if (profileImageUrl != null) "profileImage": profileImageUrl,
      };
      await DbService().updateUserData(extraData: data);

      // 4️⃣ Update provider immediately to reflect changes in UI
      userProvider.updateUserData({
        "name": _nameController.text,
        "address": _addressController.text,
        "phone": _phoneController.text,
        if (profileImageUrl != null) "profileImage": profileImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Profile"),
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 🖼️ Profile Image Preview
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (user.profileImage.isNotEmpty
                            ? NetworkImage(user.profileImage)
                            : const AssetImage('assets/images/default_avatar.png')) as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _loading ? null : _pickImage,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Form Fields
                TextFormField(
                  controller: _nameController,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Name cannot be empty." : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Email cannot be empty." : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _currentPasswordController,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Current Password (required to change email)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  enabled: !_loading,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Address cannot be empty." : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Phone cannot be empty." : null,
                ),
                const SizedBox(height: 20),

                // ✅ Submit Button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Update Profile"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
