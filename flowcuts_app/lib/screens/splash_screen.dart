import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    await ApiService().init();
    if (!mounted) return;

    if (ApiService().isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ZoomIn(
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  color: Colors.black,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // App name
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.goldGradient.createShader(b),
                child: const Text(
                  'FlowCuts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 500),
              child: const Text(
                'Tu barbería en control',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Loading indicator
            FadeIn(
              delay: const Duration(milliseconds: 700),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primary.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

