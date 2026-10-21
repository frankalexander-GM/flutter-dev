import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_screen.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

/// Paso 2 del registro: confirma el código de 6 dígitos
/// (`POST /auth/verify-register`) y, si es correcto, inicia sesión.
class VerifyRegisterScreen extends StatefulWidget {
  final String email;
  final String password;
  final String sentTo;
  final String? demoCode;

  const VerifyRegisterScreen({
    super.key,
    required this.email,
    required this.password,
    required this.sentTo,
    this.demoCode,
  });

  @override
  State<VerifyRegisterScreen> createState() => _VerifyRegisterScreenState();
}

class _VerifyRegisterScreenState extends State<VerifyRegisterScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Modo demo (sin SMTP): la API devuelve el código, así que lo precargamos.
    if (widget.demoCode != null) {
      _codeController.text = widget.demoCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyAndLogin(
      email: widget.email,
      password: widget.password,
      code: code,
    );
    if (ok && mounted) _goHome();
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    await auth.verifyAndLogin(
      email: widget.email,
      password: widget.password,
      resend: true,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Codigo reenviado. Revisa tu correo.')),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    size: 56, color: DevColors.gold),
                const SizedBox(height: 16),
                Text('Confirma tu correo', style: DevTheme.display(size: 24)),
                const SizedBox(height: 8),
                Text(
                  'Enviamos un codigo de 6 digitos a ${widget.sentTo}',
                  textAlign: TextAlign.center,
                  style: DevTheme.body(size: 14, color: DevColors.mutedFg),
                ),
                if (widget.demoCode != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DevColors.gold25,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: DevColors.gold40),
                    ),
                    child: Text(
                      'Modo demo: codigo ${widget.demoCode}',
                      style: DevTheme.body(
                          size: 12,
                          w: FontWeight.w600,
                          color: DevColors.goldSoft),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: DevTheme.display(size: 28, color: DevColors.gold),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    filled: true,
                    fillColor: DevColors.cardRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DevColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DevColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: DevColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.error!,
                        style: DevTheme.body(
                            size: 13, color: DevColors.destructive),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DevColors.primary,
                          foregroundColor: DevColors.primaryFg,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Verificar y entrar',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resend,
                  child: Text(
                    'Reenviar codigo',
                    style: DevTheme.body(size: 14, color: DevColors.gold),
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
