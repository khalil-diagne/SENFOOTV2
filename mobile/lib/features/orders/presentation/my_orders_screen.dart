import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/orders/application/orders_controller.dart';
import 'package:efoot_market/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:efoot_market/shared/widgets/app_surface.dart';
import 'package:efoot_market/shared/widgets/empty_state.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ordersControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final userId = auth.user?.id;

    final all = state.orders;
    final rows = _tab == 0
        ? all.where((o) => userId != null && o.buyerId == userId).toList()
        : all.where((o) => userId != null && o.sellerId == userId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Achats')),
                ButtonSegment(value: 1, label: Text('Ventes')),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(ordersControllerProvider.notifier).refresh(),
              child: state.error != null && all.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: ErrorView(
                            message: state.error!,
                            onRetry: () =>
                                ref.read(ordersControllerProvider.notifier).refresh(),
                          ),
                        ),
                      ],
                    )
                  : rows.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(
                              title: 'Aucune commande',
                              subtitle: 'Vos achats et vos ventes apparaîtront ici.',
                              icon: Icons.receipt_long_outlined,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final order = rows[index];
                            return AppSurface(
                              onTap: () => context.push('/orders/${order.id}'),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formatFcfa(order.priceXof),
                                          style: theme.textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '#${order.id.substring(0, 8)} · '
                                          '${formatRelativeTime(order.createdAt)}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Flexible(
                                    child: OrderStatusChip(
                                      status: order.status,
                                      label: order.statusLabel,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}