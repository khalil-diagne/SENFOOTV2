import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/orders/application/orders_controller.dart';
import 'package:efoot_market/features/orders/domain/order_model.dart';
import 'package:efoot_market/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:efoot_market/shared/widgets/app_surface.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:efoot_market/shared/widgets/stadium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Color _toneColor(BuildContext context, StatusTone tone) {
  final tokens = context.tokens;
  return switch (tone) {
    StatusTone.success => tokens.success,
    StatusTone.info => tokens.info,
    StatusTone.warning => tokens.warning,
    StatusTone.danger => tokens.danger,
    StatusTone.neutral => tokens.textDim,
  };
}

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
      builder: (context) => AlertDialog(
        title: const Text('Laisser un avis'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => rating = i),
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: context.tokens.warning,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Commentaire (optionnel)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
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
          final theme = Theme.of(context);
          final actions = _actions(order, userId, role);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OrderStatusChip(
                            status: order.status,
                            label: order.statusLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('#${order.id.substring(0, 8)}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurface(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Montant', style: theme.textTheme.labelSmall),
                        Text(
                          formatFcfa(order.priceXof),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Commission ${(order.commissionRate * 100).toStringAsFixed(0)} %'
                          '${order.commissionXof != null ? ' : ${formatFcfa(order.commissionXof!)}' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (order.paymentReference != null)
                          Text(
                            'Réf. paiement : ${order.paymentReference}',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (order.autoReleaseAt != null)
                          Text(
                            'Libération auto : ${formatDateTime(order.autoReleaseAt!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (order.disputeReason != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Litige : ${order.disputeReason}',
                            style: TextStyle(color: context.tokens.danger),
                          ),
                        ],
                        if (order.resolutionNote != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text('Résolution : ${order.resolutionNote}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Historique', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < order.events.length; i++)
                    _TimelineTile(
                      event: order.events[i],
                      last: i == order.events.length - 1,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  for (final widget in actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: widget,
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

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.last});

  final OrderEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final color = _toneColor(context, orderStatusTone(event.toStatus));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: tokens.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.toStatus.replaceAll('_', ' '),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    [
                      if (event.note != null && event.note!.isNotEmpty) event.note!,
                      event.actorRole,
                      formatRelativeTime(event.createdAt),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}