import 'package:efoot_market/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  test('formatFcfa sépare les milliers par un espace', () {
    expect(formatFcfa(28000), '28 000 FCFA');
    expect(formatFcfa(1234), '1 234 FCFA');
    expect(formatFcfa(1234567), '1 234 567 FCFA');
  });

  test('formatFcfa ne produit jamais de décimales', () {
    expect(formatFcfa(0), '0 FCFA');
    expect(formatFcfa(5), '5 FCFA');
  });

  test('formatDateTime formate en fr_FR', () {
    expect(formatDateTime(DateTime(2026, 1, 5, 9, 7)), '05/01/2026 09:07');
  });
}