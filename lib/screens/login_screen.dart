import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_screen.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/auth_kit.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (ok && mounted) _goHome();
  }

  Future<void> _guest() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginAsGuest();
    if (ok && mounted) _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _goRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      body: AuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 940;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 48 : 20,
                  vertical: wide ? 36 : 22,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - (wide ? 72 : 44),
                  ),
                  child: Center(
                    child: wide
                        ? Row(
                            children: [
                              Expanded(child: _BrandSide()),
                              const SizedBox(width: 56),
                              _FormSide(
                                formKey: _formKey,
                                email: _emailController,
                                password: _passwordController,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                onLogin: _login,
                                onGuest: _guest,
                                onRegister: _goRegister,
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AuthBrandMark(size: 42),
                              const SizedBox(height: 22),
                              _FormSide(
                                formKey: _formKey,
                                email: _emailController,
                                password: _passwordController,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                onLogin: _login,
                                onGuest: _guest,
                                onRegister: _goRegister,
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Lado izquierdo (solo escritorio): marca + propuesta de valor.
class _BrandSide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBrandMark(size: 46),
        const SizedBox(height: 34),
        Text(
          'Donde tus juegos\nencuentran testers.',
          style: DevTheme.display(size: 40, w: FontWeight.w800)
              .copyWith(height: 1.12, letterSpacing: -1),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Comparte builds tempranas, recibe feedback de verdad y descubre '
            'lo que la comunidad está creando ahora mismo.',
            style: DevTheme.body(
              size: 15,
              height: 1.5,
              color: DevColors.mutedFg,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _Bullet(
          icon: Icons.science_rounded,
          text: 'Publica betas y encuentra testers',
        ),
        const _Bullet(
          icon: Icons.forum_rounded,
          text: 'Feedback real en cada versión',
        ),
        const _Bullet(
          icon: Icons.travel_explore_rounded,
          text: 'Descubre juegos antes que nadie',
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: DevColors.card.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: DevColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    size: 14,
                    color: DevColors.accentCyan,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Comunidad indie',
                    style: DevTheme.body(
                      size: 11,
                      w: FontWeight.w600,
                      color: DevColors.mutedFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: DevColors.accentCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: DevColors.accentCyan.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 15, color: DevColors.accentCyan),
          ),
          const SizedBox(width: 11),
          Text(
            text,
            style: DevTheme.body(
              size: 13.5,
              color: DevColors.foreground.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con el formulario.
class _FormSide extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final Future<void> Function() onLogin;
  final Future<void> Function() onGuest;
  final VoidCallback onRegister;

  const _FormSide({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onGuest,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 430,
      child: AuthPanel(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Iniciar sesión',
                style: DevTheme.display(size: 24, w: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Entra para publicar, probar betas y seguir a otros devs.',
                style: DevTheme.body(size: 13, color: DevColors.mutedFg),
              ),
              const SizedBox(height: 22),
              AuthField(
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                icon: Icons.alternate_email_rounded,
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Escribe tu correo';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return 'Ese correo no parece válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Contraseña',
                hint: 'Tu contraseña',
                icon: Icons.lock_outline_rounded,
                controller: password,
                obscure: obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onLogin(),
                suffix: IconButton(
                  tooltip: obscure ? 'Mostrar' : 'Ocultar',
                  iconSize: 19,
                  color: DevColors.mutedFg,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: onToggleObscure,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Escribe tu contraseña';
                  return null;
                },
              ),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: AuthErrorBanner(message: auth.error!),
                  );
                },
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return AuthButton(
                    label: 'Entrar',
                    icon: Icons.login_rounded,
                    loading: auth.isLoading,
                    onPressed: auth.isLoading ? null : onLogin,
                  );
                },
              ),
              const SizedBox(height: 18),
              const AuthOr(label: 'o entra sin cuenta'),
              const SizedBox(height: 18),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return AuthButton(
                    label: 'Explorar como invitado',
                    icon: Icons.explore_outlined,
                    primary: false,
                    height: 46,
                    onPressed: auth.isLoading ? null : onGuest,
                  );
                },
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta?',
                      style: DevTheme.body(size: 13, color: DevColors.mutedFg),
                    ),
                    TextButton(
                      onPressed: onRegister,
                      style: TextButton.styleFrom(
                        foregroundColor: DevColors.accentCyan,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Crear cuenta',
                        style: DevTheme.body(
                          size: 13,
                          w: FontWeight.w700,
                          color: DevColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
