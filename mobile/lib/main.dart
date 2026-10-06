import 'package:efoot_market/app.dart';
import 'package:efoot_market/core/storage/token_storage.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final tokenStorage = await TokenStorage.getInstance();
  runApp(
    ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
      child: const EFootApp(),
    ),
  );
}
