import 'package:flutter/material.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, required this.label});

  final String status;
  final String label;

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'CREATED':
        return scheme.tertiary;
      case 'PAID_ESCROW':
      case 'ACCESS_TRANSFERRED':
      case 'CONFIRMED_BY_BUYER':
        return scheme.primary;
      case 'RELEASED_TO_SELLER':
        return Colors.green.shade700;
      case 'DISPUTED':
        return scheme.error;
      case 'REFUNDED':
        return scheme.outline;
      default:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
