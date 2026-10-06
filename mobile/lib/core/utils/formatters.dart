import 'package:intl/intl.dart';

final NumberFormat _xof = NumberFormat('#,##0', 'fr_FR');
final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

/// Normalise les espaces insécables produits par `intl` en espace standard,
/// pour un affichage homogène (et des tests stables).
String _normalizeSpaces(String value) {
  return value.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
}

String formatFcfa(int amountXof) {
  final formatted = _normalizeSpaces(_xof.format(amountXof));
  return '$formatted FCFA';
}

String formatDateTime(DateTime value) {
  return _dateTime.format(value.toLocal());
}

String formatRelativeTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return formatDateTime(value);
}