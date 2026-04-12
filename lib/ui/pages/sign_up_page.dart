import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/auth/auth_service.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Make it yours', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('This creates a local profile on this device.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Display name', hintText: 'e.g., Aisha')), 
              const SizedBox(height: 12),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', hintText: 'you@school.edu')),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withValues(alpha: 0.55)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Icon(Icons.person_rounded, color: scheme.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name.text.trim().isEmpty ? 'Your profile preview' : _name.text.trim(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text('Level 1 • Streak 0 days', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _signUp,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final err = await auth.signUp(displayName: _name.text, email: _email.text, password: _password.text);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      context.go(AppRoutes.dashboard);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
