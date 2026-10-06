import 'package:efoot_market/features/marketplace/data/listings_repository.dart';
import 'package:efoot_market/features/marketplace/domain/listing_model.dart';
import 'package:efoot_market/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListingsState {
  const ListingsState({
    this.page,
    this.filters = const ListingFilters(),
    this.loading = false,
    this.error,
  });

  final ListingPage? page;
  final ListingFilters filters;
  final bool loading;
  final String? error;

  ListingsState copyWith({
    ListingPage? page,
    ListingFilters? filters,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ListingsState(
      page: page ?? this.page,
      filters: filters ?? this.filters,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ListingsController extends Notifier<ListingsState> {
  ListingsRepository get _repository => ref.read(listingsRepositoryProvider);

  @override
  ListingsState build() {
    Future.microtask(refresh);
    return const ListingsState();
  }

  Future<void> refresh() async {
    final filters = state.filters;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repository.fetchListings(filters);
      state = state.copyWith(page: page, loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> applyFilters(ListingFilters filters) async {
    state = state.copyWith(filters: filters, clearError: true);
    await refresh();
  }

  Future<Listing> loadDetail(String id) => _repository.fetchListing(id);
}

final listingsControllerProvider = NotifierProvider<ListingsController, ListingsState>(
  ListingsController.new,
);

final listingDetailProvider = FutureProvider.family<Listing, String>((ref, id) {
  final repository = ref.watch(listingsRepositoryProvider);
  return repository.fetchListing(id);
});
