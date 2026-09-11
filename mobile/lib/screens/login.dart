import 'package:flutter/material.dart';

import '../api/api.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'budi@lsi.com');
  final _password = TextEditingController(text: 'password123');
  late final _server = TextEditingController(text: Api.i.baseUrl);
  bool _loading = false;
  bool _obscure = true;
  bool _showServer = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await Api.i.setBaseUrl(_server.text);
      await Api.i.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.deepTeal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: C.mint, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.fingerprint_rounded,
                    color: C.deepTeal, size: 30),
              ),
              const SizedBox(height: 24),
              Text('NUSATEK HRIS',
                  style: T.sans(13,
                      weight: FontWeight.w600,
                      color: C.mint,
                      spacing: 0.08 * 13)),
              const SizedBox(height: 6),
              Text('Masuk ke\nakun karyawan',
                  style: T.sans(30,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      spacing: -0.5)),
              const SizedBox(height: 32),
              _field(
                controller: _email,
                hint: 'Email',
                icon: Icons.mail_outline_rounded,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _password,
                hint: 'Kata sandi',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                trailing: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: C.muted,
                      size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_showServer) ...[
                const SizedBox(height: 12),
                _field(
                  controller: _server,
                  hint: 'Server API',
                  icon: Icons.dns_outlined,
                  keyboard: TextInputType.url,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Masuk',
                loading: _loading,
                onPressed: _submit,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showServer = !_showServer),
                  child: Text(
                      _showServer ? 'Sembunyikan server' : 'Ubah server API',
                      style: T.sans(12,
                          weight: FontWeight.w600,
                          color: C.mint.withValues(alpha: 0.8))),
                ),
              ),
              const SizedBox(height: 8),
              _demoHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoHint() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Akun demo (seed)',
                style: T.sans(11,
                    weight: FontWeight.w600, color: C.mint, spacing: 0.5)),
            const SizedBox(height: 8),
            ...[
              ('Karyawan', 'budi@lsi.com'),
              ('Manajer', 'manager@lsi.com'),
              ('HR', 'hr@lsi.com'),
            ].map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    SizedBox(
                        width: 72,
                        child: Text(r.$1,
                            style: T.sans(11.5,
                                color: Colors.white.withValues(alpha: 0.7)))),
                    Expanded(
                        child: GestureDetector(
                      onTap: () => setState(() => _email.text = r.$2),
                      child: Text(r.$2,
                          style: T.mono(11.5,
                              color: Colors.white, weight: FontWeight.w500)),
                    )),
                  ]),
                )),
            const SizedBox(height: 2),
            Text('Sandi semua: password123',
                style: T.sans(11, color: Colors.white.withValues(alpha: 0.55))),
          ],
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: T.sans(14, color: C.ink, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: T.sans(14, color: C.muted),
        prefixIcon: Icon(icon, color: C.muted, size: 20),
        suffixIcon: trailing,
        filled: true,
        fillColor: C.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
    );
  }
}
