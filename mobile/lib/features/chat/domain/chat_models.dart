class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String senderId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
