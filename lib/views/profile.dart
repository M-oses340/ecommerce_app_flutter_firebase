import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _pageFadeController;
  late final Animation<double> _pageFadeAnimation;
  final FlutterSecureStorage storage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _pageFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pageFadeAnimation = Tween<double>(begin: 1, end: 0).animate(_pageFadeController);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageFadeController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final FlutterSecureStorage storage = const FlutterSecureStorage(); // ✅ Added

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _pageFadeController.forward();

      // ✅ Clear providers
      userProvider.cancelProvider();
      cartProvider.cancelProvider();

      // ✅ Clear Firebase session
      await AuthService().logout();

      // ✅ Clear biometric login session
      await storage.delete(key: "logged_in");

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> options = [
      {"icon": Icons.local_shipping_outlined, "text": "Orders", "onTap": () => Navigator.pushNamed(context, "/orders")},
      {"icon": Icons.discount_outlined, "text": "Discount & Offers", "onTap": () => Navigator.pushNamed(context, "/discount")},
      {"icon": Icons.support_agent, "text": "Help & Support", "onTap": () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mail us at ecommerce@shop.com"), behavior: SnackBarBehavior.floating),
        );
      }},
      {"icon": Icons.logout_outlined, "text": "Logout", "onTap": () => _logout(context), "color": Colors.redAccent},
    ];

    return FadeTransition(
      opacity: _pageFadeAnimation.drive(CurveTween(curve: Curves.easeOut)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            children: [
              // Animated Profile Card
              Consumer<UserProvider>(
                builder: (context, user, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        color: colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                                child: user.profileImage.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white70) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name.isNotEmpty ? user.name : "Guest User",
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(user.email.isNotEmpty ? user.email : "No email",
                                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                                onPressed: () => Navigator.pushNamed(context, "/update_profile"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Animated Profile Options
              Column(
                children: options.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> option = entry.value;
                  return AnimatedOptionTile(
                    icon: option['icon'],
                    text: option['text'],
                    onTap: option['onTap'],
                    color: option['color'],
                    colorScheme: colorScheme,
                    delay: Duration(milliseconds: 100 * idx),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: width * 0.8,
                child: Text(
                  "Ecommerce App v1.0.0\nThank you for shopping with us!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated profile option tile
class AnimatedOptionTile extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final ColorScheme colorScheme;
  final Duration delay;

  const AnimatedOptionTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
    required this.colorScheme,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedOptionTile> createState() => _AnimatedOptionTileState();
}

class _AnimatedOptionTileState extends State<AnimatedOptionTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future.delayed(widget.delay, () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            ListTile(
              leading: Icon(widget.icon, color: widget.color ?? widget.colorScheme.onSurface),
              title: Text(widget.text, style: TextStyle(color: widget.color ?? widget.colorScheme.onSurface, fontWeight: FontWeight.w500)),
              onTap: widget.onTap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              hoverColor: widget.colorScheme.surfaceVariant.withOpacity(0.3),
              dense: true,
            ),
            const Divider(indent: 10, endIndent: 10, thickness: 1),
          ],
        ),
      ),
    );
  }
}
