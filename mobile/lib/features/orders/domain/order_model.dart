double _parseRate(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class OrderEvent {
  const OrderEvent({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.actorId,
    required this.actorRole,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? actorId;
  final String actorRole;
  final String? note;
  final DateTime createdAt;

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      id: json['id'] as String,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String,
      actorId: json['actor_id'] as String?,
      actorRole: (json['actor_role'] ?? 'system') as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.priceXof,
    required this.commissionRate,
    this.commissionXof,
    required this.status,
    this.paymentProvider,
    this.paymentReference,
    this.escrowReleasedAt,
    this.autoReleaseAt,
    this.disputeReason,
    this.resolutionNote,
    required this.createdAt,
    required this.updatedAt,
    this.events = const [],
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final int priceXof;
  final double commissionRate;
  final int? commissionXof;
  final String status;
  final String? paymentProvider;
  final String? paymentReference;
  final DateTime? escrowReleasedAt;
  final DateTime? autoReleaseAt;
  final String? disputeReason;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderEvent> events;

  String get statusLabel {
    switch (status) {
      case 'CREATED':
        return 'Créée';
      case 'PAID_ESCROW':
        return 'En séquestre';
      case 'ACCESS_TRANSFERRED':
        return 'Accès remis';
      case 'CONFIRMED_BY_BUYER':
        return 'Confirmée par l\'acheteur';
      case 'RELEASED_TO_SELLER':
        return 'Fonds libérés';
      case 'DISPUTED':
        return 'Litige ouvert';
      case 'REFUNDED':
        return 'Remboursée';
      default:
        return status;
    }
  }

  bool get isTerminal =>
      status == 'RELEASED_TO_SELLER' || status == 'REFUNDED';

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      priceXof: (json['price_xof'] as num).toInt(),
      commissionRate: _parseRate(json['commission_rate']),
      commissionXof: (json['commission_xof'] as num?)?.toInt(),
      status: json['status'] as String,
      paymentProvider: json['payment_provider'] as String?,
      paymentReference: json['payment_reference'] as String?,
      escrowReleasedAt: json['escrow_released_at'] == null
          ? null
          : DateTime.parse(json['escrow_released_at'] as String),
      autoReleaseAt: json['auto_release_at'] == null
          ? null
          : DateTime.parse(json['auto_release_at'] as String),
      disputeReason: json['dispute_reason'] as String?,
      resolutionNote: json['resolution_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      events: [
        for (final item in (json['events'] as List? ?? const []))
          OrderEvent.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

class ReviewPayload {
  const ReviewPayload({required this.rating, this.comment});

  final int rating;
  final String? comment;
}
