class ListingImage {
  const ListingImage({required this.id, required this.url, required this.position});

  final String id;
  final String url;
  final int position;

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    return ListingImage(
      id: json['id'] as String,
      url: json['url'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

class SellerPublic {
  const SellerPublic({
    required this.id,
    required this.username,
    required this.fullName,
    this.avgRating,
    this.reviewsCount = 0,
  });

  final String id;
  final String username;
  final String fullName;
  final double? avgRating;
  final int reviewsCount;

  factory SellerPublic.fromJson(Map<String, dynamic> json) {
    return SellerPublic(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: (json['full_name'] ?? json['username']) as String,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.priceXof,
    required this.platform,
    this.teamStrength,
    this.accountLevel,
    required this.status,
    required this.images,
    this.seller,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sellerId;
  final String title;
  final String description;
  final int priceXof;
  final String platform;
  final int? teamStrength;
  final int? accountLevel;
  final String status;
  final List<ListingImage> images;
  final SellerPublic? seller;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'active';

  String get platformLabel {
    switch (platform) {
      case 'ps4':
        return 'PS4';
      case 'ps5':
        return 'PS5';
      case 'xbox':
        return 'Xbox';
      case 'mobile':
        return 'Mobile';
      case 'pc':
        return 'PC';
      default:
        return platform.toUpperCase();
    }
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priceXof: (json['price_xof'] as num).toInt(),
      platform: json['platform'] as String,
      teamStrength: (json['team_strength'] as num?)?.toInt(),
      accountLevel: (json['account_level'] as num?)?.toInt(),
      status: json['status'] as String,
      images: [
        for (final item in (json['images'] as List? ?? const []))
          ListingImage.fromJson(item as Map<String, dynamic>),
      ],
      seller: json['seller'] == null
          ? null
          : SellerPublic.fromJson(json['seller'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ListingPage {
  const ListingPage({required this.items, required this.total, required this.page, required this.pageSize});

  final List<Listing> items;
  final int total;
  final int page;
  final int pageSize;

  factory ListingPage.fromJson(Map<String, dynamic> json) {
    return ListingPage(
      items: [
        for (final item in (json['items'] as List? ?? const []))
          Listing.fromJson(item as Map<String, dynamic>),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
    );
  }
}

class ListingFilters {
  const ListingFilters({
    this.query,
    this.platform,
    this.minPrice,
    this.maxPrice,
    this.teamStrength,
  });

  final String? query;
  final String? platform;
  final int? minPrice;
  final int? maxPrice;
  final int? teamStrength;

  ListingFilters copyWith({
    String? query,
    String? platform,
    int? minPrice,
    int? maxPrice,
    int? teamStrength,
    bool clearPlatform = false,
    bool clearQuery = false,
    bool clearPrices = false,
    bool clearTeamStrength = false,
  }) {
    return ListingFilters(
      query: clearQuery ? null : (query ?? this.query),
      platform: clearPlatform ? null : (platform ?? this.platform),
      minPrice: clearPrices ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrices ? null : (maxPrice ?? this.maxPrice),
      teamStrength: clearTeamStrength ? null : (teamStrength ?? this.teamStrength),
    );
  }

  Map<String, dynamic> toQuery() {
    return {
      if (query != null && query!.isNotEmpty) 'q': query,
      if (platform != null) 'platform': platform,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (teamStrength != null) 'team_strength': teamStrength,
      'page': 1,
      'page_size': 50,
    };
  }
}
