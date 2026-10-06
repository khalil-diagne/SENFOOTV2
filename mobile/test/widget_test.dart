import 'package:efoot_market/app.dart';
import 'package:efoot_market/core/auth/auth_events.dart';
import 'package:efoot_market/features/auth/domain/auth_models.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  Widget buildApp({
    required FakeTokenStorage storage,
    FakeAuthRepository? auth,
  }) {
    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(tokenStorage: storage),
        ),
        listingsRepositoryProvider.overrideWithValue(
          FakeListingsRepository(tokenStorage: storage),
        ),
      ],
      child: const EFootApp(),
    );
  }

  testWidgets('sans token : redirige vers l\'écran de connexion', (tester) async {
    final storage = FakeTokenStorage();

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Marketplace'), findsNothing);
  });

  testWidgets('token valide : accède à la marketplace', (tester) async {
    final storage = FakeTokenStorage(
      access: 'access-token',
      refresh: 'refresh-token',
    );

    await tester.pumpWidget(
      buildApp(
        storage: storage,
        auth: FakeAuthRepository(
          tokenStorage: storage,
          user: const UserSession(
            id: 'user-1',
            email: 'vendeur@efoot.sn',
            username: 'vendeur',
            fullName: 'Vendeur Test',
            role: 'seller',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marketplace'), findsOneWidget);
  });

  testWidgets('session expirée : redirige vers la connexion', (tester) async {
    final storage = FakeTokenStorage(
      access: 'access-token',
      refresh: 'refresh-token',
    );
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            tokenStorage: storage,
            user: const UserSession(
              id: 'user-1',
              email: 'vendeur@efoot.sn',
              username: 'vendeur',
              fullName: 'Vendeur Test',
              role: 'seller',
            ),
          ),
        ),
        listingsRepositoryProvider.overrideWithValue(
          FakeListingsRepository(tokenStorage: storage),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EFootApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Marketplace'), findsOneWidget);

    // L'intercepteur HTTP émet cet événement quand le refresh échoue.
    container.read(authEventsProvider.notifier).sessionExpired();
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Marketplace'), findsNothing);
  });
}