import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/auth_kit.dart';
import 'verify_register_screen.dart';

/// Paso 1 del registro: datos de la cuenta. Al enviar, la API FastAPI crea
/// la cuenta y manda un código de 6 dígitos (`POST /auth/register`),
/// así que se pasa al paso 2 (`VerifyRegisterScreen`).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      final result = await auth.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyRegisterScreen(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            sentTo: result.sentTo,
            demoCode: result.demoCode,
          ),
        ),
      );
    } catch (_) {
      // El error ya quedó en AuthProvider.error y se muestra en el panel.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevColors.background,
      body: AuthBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 940;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 48 : 20,
                      vertical: wide ? 30 : 22,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (wide ? 60 : 44),
                      ),
                      child: Center(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: _BrandSide()),
                                  const SizedBox(width: 56),
                                  _buildForm(context, compact: false),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AuthBrandMark(size: 40),
                                  const SizedBox(height: 18),
                                  _buildForm(context, compact: true),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 8,
                top: 6,
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: DevColors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool compact}) {
    return SizedBox(
      width: 452,
      child: AuthPanel(
        maxWidth: 452,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DevColors.accentCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: DevColors.accentCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'PASO 1 DE 2',
                      style: DevTheme.labelCaps(
                        size: 9,
                        color: DevColors.accentCyan,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (compact)
                    Text(
                      'DevPlay',
                      style: DevTheme.display(size: 15).copyWith(
                        letterSpacing: -0.3,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Crea tu cuenta',
                style: DevTheme.display(size: 24, w: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Te enviaremos un código de 6 dígitos para confirmar el correo.',
                style: DevTheme.body(size: 13, color: DevColors.mutedFg),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AuthField(
                      label: 'Usuario',
                      hint: 'tunombre',
                      icon: Icons.alternate_email_rounded,
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Elige un usuario';
                        if (value.length < 3 || value.length > 20) {
                          return 'Entre 3 y 20 caracteres';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Solo letras, números y _';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    child: AuthField(
                      label: 'Edad',
                      hint: '18',
                      icon: Icons.cake_outlined,
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final age = int.tryParse((v ?? '').trim());
                        if (age == null) return 'Edad';
                        if (age < 13) return '13+';
                        if (age > 120) return '≤120';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Nombre completo',
                hint: 'Cómo quieres que te llamen',
                icon: Icons.badge_outlined,
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.length < 3) return 'Mínimo 3 caracteres';
                  if (value.length > 30) return 'Máximo 30 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
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
                hint: 'Mínimo 6 caracteres',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                suffix: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                  iconSize: 19,
                  color: DevColors.mutedFg,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 9),
              _PasswordStrength(password: _passwordController.text),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: AuthErrorBanner(message: auth.error!),
                  );
                },
              ),
              const SizedBox(height: 18),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return AuthButton(
                    label: 'Continuar',
                    icon: Icons.arrow_forward_rounded,
                    loading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _submit,
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Al crear tu cuenta aceptas las normas de la comunidad: respeto, '
                'crédito al autor y cero spam.',
                style: DevTheme.body(
                  size: 11,
                  height: 1.4,
                  color: DevColors.disabled,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta?',
                      style: DevTheme.body(size: 13, color: DevColors.mutedFg),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: TextButton.styleFrom(
                        foregroundColor: DevColors.accentCyan,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Inicia sesión',
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

/// Barra de 3 tramos con la fuerza de la contraseña.
class _PasswordStrength extends StatelessWidget {
  final String password;

  const _PasswordStrength({required this.password});

  int get _score {
    if (password.isEmpty) return 0;
    var score = 1;
    if (password.length >= 8) score++;
    final hasMix = RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
    if (hasMix && password.length >= 10) score++;
    return score.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    const labels = ['Débil', 'Aceptable', 'Fuerte'];
    final colors = [
      DevColors.destructive,
      DevColors.amber,
      DevColors.consoleGreen,
    ];
    final score = _score;

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              decoration: BoxDecoration(
                color: i < score
                    ? colors[(score - 1).clamp(0, 2)]
                    : DevColors.muted,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 5),
        ],
        const SizedBox(width: 10),
        Text(
          score == 0 ? 'Débil' : labels[(score - 1).clamp(0, 2)],
          style: DevTheme.body(
            size: 10.5,
            w: FontWeight.w700,
            color: score == 0
                ? DevColors.mutedFg
                : colors[(score - 1).clamp(0, 2)],
          ),
        ),
      ],
    );
  }
}

class _BrandSide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBrandMark(size: 46),
        const SizedBox(height: 30),
        Text(
          'Tu estudio empieza\ncon una beta.',
          style: DevTheme.display(size: 38, w: FontWeight.w800)
              .copyWith(height: 1.12, letterSpacing: -1),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Crea tu perfil, publica la primera build y deja que la comunidad '
            'la pruebe. Sin intermediarios.',
            style: DevTheme.body(
              size: 15,
              height: 1.5,
              color: DevColors.mutedFg,
            ),
          ),
        ),
        const SizedBox(height: 26),
        const _Feature(
          icon: Icons.science_rounded,
          title: 'Betas con ficha completa',
          text: 'Plataformas, requisitos, changelog y capturas.',
        ),
        const _Feature(
          icon: Icons.insights_rounded,
          title: 'Descargas y feedback',
          text: 'Mira cómo responde tu build en cada versión.',
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Feature({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DevColors.accentCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: DevColors.accentCyan.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 16, color: DevColors.accentCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DevTheme.body(size: 13.5, w: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: DevTheme.body(size: 12, color: DevColors.mutedFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
