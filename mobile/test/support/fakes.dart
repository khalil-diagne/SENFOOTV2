import 'package:efoot_market/core/network/api_client.dart';
import 'package:efoot_market/core/storage/token_storage.dart';
import 'package:efoot_market/features/auth/data/auth_repository.dart';
import 'package:efoot_market/features/auth/domain/auth_models.dart';
import 'package:efoot_market/features/marketplace/data/listings_repository.dart';
import 'package:efoot_market/features/marketplace/domain/listing_model.dart';

/// TokenStorage en mémoire : aucun accès disque, comportement identique à
/// l'implémentation partagée.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> accessToken() async => access;

  @override
  Future<String?> refreshToken() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// Renvoie un utilisateur fixe (ou null) sans appel réseau.
class FakeAuthRepository extends AuthRepository {
  // ignore: use_super_parameters
  FakeAuthRepository({required TokenStorage tokenStorage, this.user})
      : super(
          api: ApiClient(tokenStorage: tokenStorage),
          tokenStorage: tokenStorage,
        );

  final UserSession? user;

  @override
  Future<UserSession?> currentUser() async => user;
}

/// Renvoie une page vide sans appel réseau.
class FakeListingsRepository extends ListingsRepository {
  FakeListingsRepository({required TokenStorage tokenStorage})
      : super(api: ApiClient(tokenStorage: tokenStorage));

  @override
  Future<ListingPage> fetchListings(ListingFilters filters) async {
    return const ListingPage(items: [], total: 0, page: 1, pageSize: 20);
  }
}