import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService().login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => _error = result['message'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      setState(() => _error = 'No se pudo conectar al servidor.\nVerifica tu conexión.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo & Title
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.content_cut_rounded,
                          color: Colors.black,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.goldGradient.createShader(bounds),
                        child: const Text(
                          'FlowCuts',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Panel de Administración',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Form
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ingresa tus credenciales de administrador',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Username field
                      TextFormField(
                        controller: _usernameCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          hintText: 'Tu nombre de usuario',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ingresa tu usuario' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppTheme.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Footer
              FadeIn(
                delay: const Duration(milliseconds: 500),
                child: Center(
                  child: Text(
                    '${AppConstants.appName} v${AppConstants.version}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
