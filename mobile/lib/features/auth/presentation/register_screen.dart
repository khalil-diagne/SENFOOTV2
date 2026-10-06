import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/shared/widgets/stadium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'buyer';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            fullName: _fullNameController.text.trim(),
            password: _passwordController.text,
            role: _role,
            phone: _phoneController.text.trim(),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: 72,
                    child: PitchBackdrop(child: SizedBox.shrink()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) return 'Username (min. 3)';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || !v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (optionnel)',
                      hintText: '+221 77 000 00 00',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe (min. 8)'),
                    validator: (v) {
                      if (v == null || v.length < 8) return '8 caractères minimum';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'buyer', label: Text('Acheteur')),
                      ButtonSegment(value: 'seller', label: Text('Vendeur')),
                    ],
                    selected: {_role},
                    onSelectionChanged: (value) => setState(() => _role = value.first),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Un compte vendeur peut acheter et vendre.',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
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
                        : const Text('S\'inscrire'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('J\'ai déjà un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}