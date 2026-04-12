import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_flow/features/auth/auth_service.dart';
import 'package:study_flow/nav.dart';
import 'package:study_flow/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'student@example.com');
  final _password = TextEditingController(text: 'password');
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withValues(alpha: 0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(Icons.school_rounded, color: scheme.onPrimary),
              ),
              const SizedBox(height: 14),
              Text('Welcome back', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Sign in to continue your productivity streak.', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
              const SizedBox(height: 18),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'you@school.edu'),
              ),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _login,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login_rounded),
                  label: const Text('Log in'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  TextButton(
                    onPressed: _loading ? null : () => context.push(AppRoutes.signUp),
                    child: Text('Create one', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final err = await auth.login(email: _email.text, password: _password.text);
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
