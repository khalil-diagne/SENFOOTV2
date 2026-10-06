import 'package:efoot_market/shared/widgets/empty_state.dart';
import 'package:efoot_market/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyTitle = 'Aucun résultat',
    this.emptySubtitle,
  });

  final T? value;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;
  final bool Function(T value)? isEmpty;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final current = value;
    if (current == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final empty = isEmpty?.call(current) ?? false;
    if (empty) {
      return EmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }
    return builder(current);
  }
}

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorView(message: error.toString(), onRetry: onRetry);
  }
}
