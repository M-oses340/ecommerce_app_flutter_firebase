import 'dart:io';
import 'dart:ui';
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

class _UpdateProfileState extends State<UpdateProfile> with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  final TextEditingController _currentPasswordController = TextEditingController();

  bool _loading = false;
  File? _selectedImage;

  // Avatar animation
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;

  // Loading shimmer pulse
  late AnimationController _loadingController;
  late Animation<double> _pulseAnimation;

  // Shake animations
  late AnimationController _nameControllerAnim;
  late AnimationController _emailControllerAnim;
  late AnimationController _passwordControllerAnim;
  late AnimationController _addressControllerAnim;
  late AnimationController _phoneControllerAnim;

  // Fade-in opacity controls
  double _nameOpacity = 0.0;
  double _emailOpacity = 0.0;
  double _passwordOpacity = 0.0;
  double _addressOpacity = 0.0;
  double _phoneOpacity = 0.0;
  double _buttonOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _addressController = TextEditingController(text: user.address);
    _phoneController = TextEditingController(text: user.phone);

    _initAnimations();
    _startFadeSequence();
  }

  void _initAnimations() {
    _avatarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _avatarScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeOutBack),
    );
    _avatarController.forward();

    _loadingController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _nameControllerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _emailControllerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _passwordControllerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _addressControllerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _phoneControllerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  void _startFadeSequence() {
    const delayStep = 400;
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _nameOpacity = 1.0));
    Future.delayed(Duration(milliseconds: 200 + delayStep), () => setState(() => _emailOpacity = 1.0));
    Future.delayed(Duration(milliseconds: 200 + 2 * delayStep), () => setState(() => _passwordOpacity = 1.0));
    Future.delayed(Duration(milliseconds: 200 + 3 * delayStep), () => setState(() => _addressOpacity = 1.0));
    Future.delayed(Duration(milliseconds: 200 + 4 * delayStep), () => setState(() => _phoneOpacity = 1.0));
    Future.delayed(Duration(milliseconds: 200 + 5 * delayStep), () => setState(() => _buttonOpacity = 1.0));
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _loadingController.dispose();
    _nameControllerAnim.dispose();
    _emailControllerAnim.dispose();
    _passwordControllerAnim.dispose();
    _addressControllerAnim.dispose();
    _phoneControllerAnim.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _triggerShake(String field) {
    switch (field) {
      case 'name':
        _nameControllerAnim.forward(from: 0);
        break;
      case 'email':
        _emailControllerAnim.forward(from: 0);
        break;
      case 'password':
        _passwordControllerAnim.forward(from: 0);
        break;
      case 'address':
        _addressControllerAnim.forward(from: 0);
        break;
      case 'phone':
        _phoneControllerAnim.forward(from: 0);
        break;
    }
  }

  Future<void> _pickImage() async {
    if (_loading) return;
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _updateProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    debugPrint("🔹 [UpdateProfile] Update button pressed");

    if (!formKey.currentState!.validate()) {
      debugPrint("❌ [UpdateProfile] Validation failed");
      if (_nameController.text.isEmpty) _triggerShake('name');
      if (_emailController.text.isEmpty) _triggerShake('email');
      if (_currentPasswordController.text.isEmpty &&
          _emailController.text != userProvider.email) _triggerShake('password');
      if (_addressController.text.isEmpty) _triggerShake('address');
      if (_phoneController.text.isEmpty) _triggerShake('phone');
      return;
    }

    setState(() => _loading = true);
    debugPrint("🟡 [UpdateProfile] Loading state ON");

    try {
      // Email change with password check
      if (_currentPasswordController.text.isNotEmpty) {
        debugPrint("🔹 [UpdateProfile] Email is being changed...");
        final res = await AuthService().updateEmail(
          newEmail: _emailController.text.trim(),
          currentPassword: _currentPasswordController.text.trim(),
        );
        debugPrint("🔸 [UpdateProfile] updateEmail() result: $res");

        if (res == "wrong-password") {
          _triggerShake('password');
          throw "Incorrect current password.";
        } else if (res == "email-already-in-use") {
          throw "This email is already in use.";
        } else if (res != "success") {
          throw "Failed to update Profile ($res)";
        }
        userProvider.updateUserData({"email": _emailController.text.trim()});
      }

      String? profileImageUrl;
      if (_selectedImage != null) {
        debugPrint("🟦 [UpdateProfile] Uploading new profile image...");
        profileImageUrl = await DbService().uploadProfileImage(_selectedImage!);
      }

      final data = {
        "name": _nameController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        if (profileImageUrl != null) "profileImage": profileImageUrl,
      };

      debugPrint("🟢 [UpdateProfile] Updating Firestore data: $data");
      await DbService().updateUserData(extraData: data);
      userProvider.updateUserData(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      debugPrint("✅ [UpdateProfile] Profile updated successfully");
    } catch (e) {
      debugPrint("❌ [UpdateProfile] Exception: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      debugPrint("⚪ [UpdateProfile] Loading state OFF");
    }
  }

  Future<bool> _assetExists(String path) async {
    try {
      final assetBundle = DefaultAssetBundle.of(context);
      final data = await assetBundle.load(path);
      return data.lengthInBytes > 0; // ✅ Correct way to check if asset exists
    } catch (_) {
      debugPrint("⚠️ Asset missing: $path");
      return false;
    }
  }


  Widget _shakeWrapper(AnimationController controller, Widget child) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
        ]).animate(controller);
        return Transform.translate(offset: Offset(offset.value, 0), child: child);
      },
    );
  }

  Widget _animatedField({required double opacity, required Widget child}) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inputDecoration = InputDecoration(
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.white,
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Profile"),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _loading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _avatarScale,
                      child: Center(
                        child: Stack(
                          children: [
                            FutureBuilder<bool>(
                              future: _assetExists('assets/images/default_avatar.png'),
                              builder: (context, snapshot) {
                                ImageProvider imageProvider;

                                if (_selectedImage != null) {
                                  imageProvider = FileImage(_selectedImage!);
                                } else if (user.profileImage.isNotEmpty) {
                                  imageProvider = NetworkImage(user.profileImage);
                                } else if (snapshot.connectionState == ConnectionState.done &&
                                    snapshot.data == true) {
                                  imageProvider = const AssetImage('assets/images/default_avatar.png');
                                } else {
                                  // Network fallback avatar
                                  imageProvider = const NetworkImage(
                                    'https://ui-avatars.com/api/?background=0D8ABC&color=fff&name=User',
                                  );
                                }

                                return CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: imageProvider,
                                  onBackgroundImageError: (_, __) {
                                    debugPrint("⚠️ Failed to load profile image.");
                                  },
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _loading ? null : _pickImage,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _animatedField(
                      opacity: _nameOpacity,
                      child: _shakeWrapper(
                        _nameControllerAnim,
                        TextFormField(
                          controller: _nameController,
                          decoration: inputDecoration.copyWith(labelText: "Name"),
                          validator: (v) => v!.isEmpty ? "Name cannot be empty" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _animatedField(
                      opacity: _emailOpacity,
                      child: _shakeWrapper(
                        _emailControllerAnim,
                        TextFormField(
                          controller: _emailController,
                          decoration: inputDecoration.copyWith(labelText: "Email"),
                          validator: (v) => v!.isEmpty ? "Email cannot be empty" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _animatedField(
                      opacity: _passwordOpacity,
                      child: _shakeWrapper(
                        _passwordControllerAnim,
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: inputDecoration.copyWith(
                            labelText: "Current Password (required if changing email)",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _animatedField(
                      opacity: _addressOpacity,
                      child: _shakeWrapper(
                        _addressControllerAnim,
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: inputDecoration.copyWith(labelText: "Address"),
                          validator: (v) => v!.isEmpty ? "Address cannot be empty" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _animatedField(
                      opacity: _phoneOpacity,
                      child: _shakeWrapper(
                        _phoneControllerAnim,
                        TextFormField(
                          controller: _phoneController,
                          decoration: inputDecoration.copyWith(labelText: "Phone"),
                          validator: (v) => v!.isEmpty ? "Phone cannot be empty" : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    AnimatedOpacity(
                      opacity: _buttonOpacity,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: width,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          child: const Text("Update Profile"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: theme.colorScheme.surface.withOpacity(0.3),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Center(
                      child: Opacity(
                        opacity: _pulseAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 4,
                              color: theme.colorScheme.primary.withOpacity(0.9),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Updating Profile...",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
