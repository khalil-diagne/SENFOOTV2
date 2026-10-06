import 'package:efoot_market/core/utils/formatters.dart';
import 'package:efoot_market/features/auth/application/auth_controller.dart';
import 'package:efoot_market/features/orders/application/orders_controller.dart';
import 'package:efoot_market/features/orders/domain/order_model.dart';
import 'package:efoot_market/features/orders/presentation/widgets/order_status_chip.dart';
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
    final state = ref.watch(ordersControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final userId = auth.user?.id;

    final all = state.orders;
    final purchases = userId == null
        ? <Order>[]
        : all.where((order) => order.buyerId == userId).toList();
    final sales = userId == null
        ? <Order>[]
        : all.where((order) => order.sellerId == userId).toList();
    final items = _tab == 0 ? purchases : sales;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              child: state.error != null && items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: ErrorView(
                            message: state.error!,
                            onRetry: () =>
                                ref.read(ordersControllerProvider.notifier).refresh(),
                          ),
                        ),
                      ],
                    )
                  : items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Aucune commande pour l\'instant.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = items[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '${formatFcfa(order.priceXof)} · #${order.id.substring(0, 8)}',
                                ),
                                subtitle: Text(formatRelativeTime(order.createdAt)),
                                trailing: OrderStatusChip(
                                  status: order.status,
                                  label: order.statusLabel,
                                ),
                                onTap: () => context.push('/orders/${order.id}'),
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
