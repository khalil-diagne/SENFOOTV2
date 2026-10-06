import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/shared/widgets/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: tokens.surfaceHigh,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                user?.fullName ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '@${user?.username ?? ''} · ${user?.role ?? ''}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(user?.email ?? '', style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => context.go('/orders'),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Mes commandes'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}