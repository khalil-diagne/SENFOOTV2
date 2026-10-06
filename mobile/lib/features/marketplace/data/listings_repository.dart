import 'package:efoot_market/core/network/api_client.dart';
import 'package:efoot_market/core/network/api_exception.dart';
import 'package:efoot_market/features/marketplace/domain/listing_model.dart';

class ListingsRepository {
  ListingsRepository({required this.api});

  final ApiClient api;

  Future<ListingPage> fetchListings(ListingFilters filters) async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>(
        '/api/v1/listings',
        queryParameters: filters.toQuery(),
      );
      return ListingPage.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Listing> fetchListing(String id) async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>('/api/v1/listings/$id');
      return Listing.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Listing> createListing({
    required String title,
    required String description,
    required int priceXof,
    required String platform,
    int? teamStrength,
    int? accountLevel,
    List<String> imageUrls = const [],
  }) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/listings',
        data: {
          'title': title,
          'description': description,
          'price_xof': priceXof,
          'platform': platform,
          if (teamStrength != null) 'team_strength': teamStrength,
          if (accountLevel != null) 'account_level': accountLevel,
          'status': 'active',
          'image_urls': imageUrls,
        },
      );
      return Listing.fromJson(response.data!);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
