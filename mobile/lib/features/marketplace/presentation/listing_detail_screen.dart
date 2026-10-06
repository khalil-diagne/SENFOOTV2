import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/marketplace/application/listings_controller.dart';
import 'package:efoot_market/features/orders/application/orders_controller.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
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
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (listing.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          listing.images.first.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(Icons.sports_esports, size: 48),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(listing.platformLabel)),
                      if (listing.teamStrength != null) ...[
                        const SizedBox(width: 8),
                        Chip(label: Text('Puissance ${listing.teamStrength}')),
                      ],
                      if (listing.accountLevel != null) ...[
                        const SizedBox(width: 8),
                        Chip(label: Text('Niv. ${listing.accountLevel}')),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatFcfa(listing.priceXof),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (listing.seller != null)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(listing.seller!.fullName),
                        subtitle: Text(
                          listing.seller!.avgRating == null
                              ? listing.seller!.username
                              : '${listing.seller!.username} · ★ ${listing.seller!.avgRating!.toStringAsFixed(1)} '
                                  '(${listing.seller!.reviewsCount} avis)',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('Description', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(listing.description),
                  const SizedBox(height: 24),
                  if (auth.user != null && auth.user!.id == listing.sellerId)
                    FilledButton.tonal(
                      onPressed: () => context.push('/sell'),
                      child: const Text('Vous êtes le vendeur de cette annonce'),
                    )
                  else if (auth.isAuthenticated && listing.isActive)
                    FilledButton(
                      onPressed: _busy ? null : _buy,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Acheter avec séquestre'),
                    )
                  else if (!auth.isAuthenticated)
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
