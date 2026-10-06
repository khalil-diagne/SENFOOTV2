import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/shared/widgets/stadium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go('/');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: 120,
                      child: PitchBackdrop(
                        opacity: 0.35,
                        child: Center(
                          child: Text('EFoot Market SN'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Email requis';
                        if (!value.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Mot de passe requis';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: TextStyle(color: context.tokens.danger),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Pas encore de compte ? S\'inscrire'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}