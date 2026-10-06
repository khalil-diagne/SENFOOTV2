import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/marketplace/application/listings_controller.dart';
import 'package:efoot_market/features/orders/application/orders_controller.dart';
import 'package:efoot_market/shared/widgets/app_surface.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:efoot_market/shared/widgets/stadium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }
    if (!auth.user!.canBuy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre rôle ne permet pas d\'acheter.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final order = await ref
          .read(ordersControllerProvider.notifier)
          .createOrder(listingId: widget.listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande créée. Payez pour lancer le séquestre.')),
      );
      context.pushReplacement('/orders/${order.id}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDetailProvider(widget.listingId));
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'annonce')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(listingDetailProvider(widget.listingId)),
        ),
        data: (listing) {
          final theme = Theme.of(context);
          final tokens = context.tokens;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (listing.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          listing.images.first.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: tokens.surfaceHigh,
                            alignment: Alignment.center,
                            child: const Icon(Icons.sports_esports, size: 48),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (listing.teamStrength != null) ...[
                    PowerNumeral(value: listing.teamStrength!, size: 64),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(listing.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Chip(label: Text(listing.platformLabel)),
                      if (listing.accountLevel != null)
                        Chip(label: Text('Niv. ${listing.accountLevel}')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prix', style: theme.textTheme.labelSmall),
                        Text(
                          formatFcfa(listing.priceXof),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Le montant reste en séquestre jusqu\'à confirmation de la réception.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (listing.seller != null)
                    AppSurface(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              listing.seller!.fullName.isNotEmpty
                                  ? listing.seller!.fullName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.seller!.fullName,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  listing.seller!.avgRating == null
                                      ? '@${listing.seller!.username}'
                                      : '@${listing.seller!.username} · '
                                          '★ ${listing.seller!.avgRating!.toStringAsFixed(1)} '
                                          '(${listing.seller!.reviewsCount} avis)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Description', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(listing.description),
                  const SizedBox(height: AppSpacing.lg),
                  if (auth.user != null && auth.user!.id == listing.sellerId)
                    FilledButton.tonal(
                      onPressed: () => context.push('/sell'),
                      child: const Text('Vous êtes le vendeur de cette annonce'),
                    )
                  else if (auth.isAuthenticated && listing.isActive) ...[
                    FilledButton(
                      onPressed: _busy ? null : _buy,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Acheter avec séquestre'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: tokens.info),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Votre paiement est retenu jusqu\'à la remise des accès.',
                          style: theme.textTheme.bodySmall?.copyWith(color: tokens.info),
                        ),
                      ],
                    ),
                  ] else if (!auth.isAuthenticated)
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Connectez-vous pour acheter'),
                    )
                  else
                    FilledButton(
                      onPressed: null,
                      child: Text('Annonce ${listing.status}'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}