import 'package:efoot_market/shared/widgets/stadium_widgets.dart';
import 'package:flutter/material.dart';

StatusTone orderStatusTone(String status) {
  switch (status) {
    case 'PAID_ESCROW':
      return StatusTone.info;
    case 'ACCESS_TRANSFERRED':
      return StatusTone.warning;
    case 'CONFIRMED_BY_BUYER':
    case 'RELEASED_TO_SELLER':
      return StatusTone.success;
    case 'DISPUTED':
      return StatusTone.danger;
    case 'CREATED':
    case 'REFUNDED':
    default:
      return StatusTone.neutral;
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: label, tone: orderStatusTone(status));
  }
}