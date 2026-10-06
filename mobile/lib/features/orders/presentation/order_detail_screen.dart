import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/orders/application/orders_controller.dart';
import 'package:efoot_market/features/orders/domain/order_model.dart';
import 'package:efoot_market/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(orderDetailProvider(widget.orderId));
      await ref.read(ordersControllerProvider.notifier).refresh();
      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askNote(
    String title,
    String actionLabel,
    Future<void> Function(String note) onSubmit,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (note == null) return;
    await _run(() => onSubmit(note));
  }

  Future<void> _openDispute() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ouvrir un litige'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Expliquez le problème (min. 10 caractères)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (reason == null || reason.length < 10) return;
    await _run(
      () =>
          ref.read(ordersControllerProvider.notifier).dispute(widget.orderId, reason: reason),
      successMessage: 'Litige ouvert',
    );
  }

  Future<void> _resolve(String action) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'refund' ? 'Rembourser l\'acheteur' : 'Libérer les fonds au vendeur'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Note de résolution (obligatoire)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (note == null || note.length < 5) return;
    await _run(
      () => ref
          .read(ordersControllerProvider.notifier)
          .resolve(widget.orderId, action: action, resolutionNote: note),
      successMessage: 'Litige résolu',
    );
  }

  Future<void> _leaveReview() async {
    var rating = 5;
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Noter cette commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setDialogState(() => rating = i),
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: commentController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Commentaire (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(ordersControllerProvider.notifier).createReview(
            widget.orderId,
            rating: rating,
            comment: commentController.text.trim(),
          ),
      successMessage: 'Merci pour votre avis !',
    );
  }

  List<Widget> _actions(Order order, String userId, String role) {
    final widgets = <Widget>[];
    final notifier = ref.read(ordersControllerProvider.notifier);
    final isBuyer = order.buyerId == userId;
    final isSeller = order.sellerId == userId;
    final isAdmin = role == 'admin';

    if (isBuyer && order.status == 'CREATED') {
      widgets.add(
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(
                    () => notifier.pay(widget.orderId),
                    successMessage: 'Paiement séquestre enregistré',
                  ),
          child: const Text('Payer (séquestre)'),
        ),
      );
    }
    if (isSeller && order.status == 'PAID_ESCROW') {
      widgets.add(
        FilledButton(
          onPressed: _busy
              ? null
              : () => _askNote('Marquer les accès remis', 'Confirmer', (note) async {
                  await ref.read(ordersControllerProvider.notifier).transferAccess(
                        widget.orderId,
                        note: note.isEmpty ? 'Accès remis à l\'acheteur' : note,
                      );
                }),
          child: const Text('Accès remis'),
        ),
      );
    }
    if (isBuyer && order.status == 'ACCESS_TRANSFERRED') {
      widgets.add(
        FilledButton(
          onPressed: _busy
              ? null
              : () => _askNote('Confirmer la réception', 'Confirmer et libérer', (note) async {
                  await ref.read(ordersControllerProvider.notifier).confirm(
                        widget.orderId,
                        note: note.isEmpty ? 'Réception confirmée' : note,
                      );
                }),
          child: const Text('Confirmer la réception'),
        ),
      );
    }
    if ((isBuyer || isSeller) &&
        (order.status == 'PAID_ESCROW' || order.status == 'ACCESS_TRANSFERRED')) {
      widgets.add(
        OutlinedButton(
          onPressed: _busy ? null : _openDispute,
          child: const Text('Ouvrir un litige'),
        ),
      );
    }
    if (isAdmin && order.status == 'DISPUTED') {
      widgets.add(
        FilledButton.tonal(
          onPressed: _busy ? null : () => _resolve('release'),
          child: const Text('Libérer au vendeur'),
        ),
      );
      widgets.add(
        OutlinedButton(
          onPressed: _busy ? null : () => _resolve('refund'),
          child: const Text('Rembourser l\'acheteur'),
        ),
      );
    }
    if (order.status == 'RELEASED_TO_SELLER' && (isBuyer || isSeller)) {
      widgets.add(
        FilledButton.tonal(
          onPressed: _busy ? null : _leaveReview,
          child: const Text('Laisser un avis'),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderId));
    final auth = ref.watch(authControllerProvider);
    final userId = auth.user?.id ?? '';
    final role = auth.user?.role ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Commande')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          final actions = _actions(order, userId, role);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      OrderStatusChip(status: order.status, label: order.statusLabel),
                      const Spacer(),
                      Text('#${order.id.substring(0, 8)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Montant', style: Theme.of(context).textTheme.labelLarge),
                          Text(
                            formatFcfa(order.priceXof),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commission ${(order.commissionRate * 100).toStringAsFixed(0)} %'
                            '${order.commissionXof != null ? ' : ${formatFcfa(order.commissionXof!)}' : ''}',
                          ),
                          if (order.paymentReference != null)
                            Text('Réf. paiement : ${order.paymentReference}'),
                          if (order.autoReleaseAt != null)
                            Text(
                              'Libération auto : ${formatDateTime(order.autoReleaseAt!)}',
                            ),
                          if (order.disputeReason != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Litige : ${order.disputeReason}',
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ],
                          if (order.resolutionNote != null) ...[
                            const SizedBox(height: 8),
                            Text('Résolution : ${order.resolutionNote}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Historique', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...order.events.map(
                    (event) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 10),
                      title: Text(event.toStatus.replaceAll('_', ' ')),
                      subtitle: Text(
                        [
                          if (event.note != null && event.note!.isNotEmpty) event.note!,
                          event.actorRole,
                          formatRelativeTime(event.createdAt),
                        ].join(' · '),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...actions.map(
                    (widget) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: widget,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/orders/${order.id}/chat'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ouvrir la discussion'),
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
