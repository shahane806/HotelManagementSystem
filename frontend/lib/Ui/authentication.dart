// lib/ui/auth_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/Ui/dashboard_screen.dart';
import 'package:frontend/repositories/user_repository.dart';
import 'package:frontend/services/apiServicesAuthentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _particleController;

  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  // final _signupName = TextEditingController();
  // final _signupEmail = TextEditingController();
  // final _signupPass = TextEditingController();
  // final _signupConfirmPass = TextEditingController();
  final _forgotEmail = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _particleController.dispose();
    super.dispose();
  }
void _login() async {
  if (_loginEmail.text.trim().isEmpty || _loginPass.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final result = await Apiservicesauthentication.loginApiService(
      _loginEmail.text.trim(),
      _loginPass.text,
    );
    print("Login : ${result}");
    // Success - Save token if needed (e.g., using shared_preferences)
    // Example: await SharedPrefs.saveToken(result['token']);
    if (result['success'] == true) {
     
      final user = result['user'];
      print("Decoded user: $user");
      UserRepository.setUserData(user);
    } else {
      // Login failed
      print("Login failed: ${result['message']}");
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
      );

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  } catch (e) {
    print("e : $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}
  // void _signup() {
  //   if (_signupPass.text != _signupConfirmPass.text) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red),
  //     );
  //     return;
  //   }
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Account created!"), backgroundColor: Colors.green),
  //   );
  //   _tabController.animateTo(0);
  // }
void _forgotPassword() async {
  if (_forgotEmail.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter your email"), backgroundColor: Colors.red),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    await Apiservicesauthentication.forgotPasswordApiService(_forgotEmail.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ← CRITICAL: Allows layout to shrink when keyboard opens
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
          ),

          // Floating Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: FloatingParticlesPainter(_particleController.value),
            ),
          ),

          isDesktop ? _desktopView() : _mobileView(),
        ],
      ),
    );
  }

  // Desktop — unchanged & perfect
  Widget _desktopView() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hotel Pro",softWrap: false, style: TextStyle(fontSize: 75, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 24),
                 Text("Next-generation hotel management\nbuilt for excellence",
                    style: TextStyle(fontSize: 28, color: Colors.white.withOpacity(0.95), height: 1.5)),
                const SizedBox(height: 50),
                Icon(Icons.hotel_class, size: 160, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _authCard(),
            ),
          ),
        ),
      ],
    );
  }

  // MOBILE — NOW 100% KEYBOARD-SAFE!
  Widget _mobileView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            // Logo & Title (only when keyboard is hidden)
            if (MediaQuery.of(context).viewInsets.bottom < 100) ...[
              Icon(Icons.hotel_class, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text("Hotel Pro", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
              Text("Welcome back", style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 30),
            ],

            // Auth Card — Auto-resizes perfectly
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: _authCard(),
              ),
            ),

            const SizedBox(height: 10),
            Text("© 2025 Hotel Pro", style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _authCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ["Welcome Back!", "Create Account", "Reset Password"][_tabController.index],
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          Text(
            ["Sign in to continue", "Join thousands of hotels", "Get back into your account"][_tabController.index],
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
            child: TabBar(
              
              controller: _tabController,
              labelColor: const Color(0xFF667eea),
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
              tabs: const [Tab(text: "Login"),Tab(text: "Forgot")],
            ),
          ),
          const SizedBox(height: 28),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey(_tabController.index),
              child: _tabController.index == 0
                  ? _loginTab()
                  : _tabController.index == 1
                      ? _forgotTab()
                      : _forgotTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginTab() => _form([
        _field(_loginEmail, "Email", Icons.alternate_email),
        _field(_loginPass, "Password", Icons.lock, true),
        const SizedBox(height: 16),
        _btn("Login", _login, const Color(0xFF667eea)),
      ]);

  // Widget _signupTab() => _form([
  //       _field(_signupName, "Full Name", Icons.person),
  //       _field(_signupEmail, "Email", Icons.alternate_email),
  //       _field(_signupPass, "Password", Icons.lock, true),
  //       _field(_signupConfirmPass, "Confirm Password", Icons.lock_outline, true,  true),
  //       const SizedBox(height: 16),
  //       _btn("Create Account", _signup, const Color(0xFF764ba2)),
  //     ]);

  Widget _forgotTab() => _form([
        const Icon(Icons.lock_reset, size: 64, color: Colors.orange),
        const SizedBox(height: 12),
        const Text("Forgot Password?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Enter your email to receive a reset link",
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 16),
        _field(_forgotEmail, "Email", Icons.email),
        const SizedBox(height: 16),
        _btn("Send Reset Link", _forgotPassword, Colors.orangeAccent),
      ]);

  Widget _form(List<Widget> children) => Column(children: children);

  Widget _field(TextEditingController c, String label, IconData icon, [bool pass = false, bool isConfirm = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        obscureText: pass && (isConfirm ? _obscureConfirm : _obscure),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          suffixIcon: pass
              ? IconButton(
                  icon: Icon(isConfirm
                      ? (_obscureConfirm ? Icons.visibility_off : Icons.visibility)
                      : (_obscure ? Icons.visibility_off : Icons.visibility)),
                  onPressed: () => setState(() {
                    if (isConfirm) _obscureConfirm = !_obscureConfirm;
                    else _obscure = !_obscure;
                  }),
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 12,
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Floating Particles (unchanged)
class FloatingParticlesPainter extends CustomPainter {
  final double animation;
  FloatingParticlesPainter(this.animation);

  final List<Particle> particles = List.generate(35, (i) {
    final r = Random(i);
    return Particle(x: r.nextDouble(), y: r.nextDouble(), size: 4 + r.nextDouble() * 10, speed: 0.2 + r.nextDouble() * 0.6);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..blendMode = BlendMode.plus;
    final dot = Paint();

    for (final p in particles) {
      final t = (animation + p.x) % 1.0;
      final y = (p.y + t * p.speed) % 1.2 - 0.1;
      final x = p.x + sin(t * 4) * 0.08;
      final offset = Offset(x * size.width, y * size.height);

      glow.color = Colors.white.withOpacity(0.15);
      canvas.drawCircle(offset, p.size * 3, glow);
      dot.color = Colors.white.withOpacity(0.6);
      canvas.drawCircle(offset, p.size, dot);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class Particle {
  final double x, y, size, speed;
  Particle({required this.x, required this.y, required this.size, required this.speed});
}