class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final dynamic details;

  factory ApiException.fromDio(dynamic error) {
    if (error is ApiException) return error;
    final response = error.response;
    if (response != null) {
      final data = response.data;
      String message = 'Erreur serveur';
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            message = first['msg'].toString();
          }
        }
      }
      return ApiException(message, statusCode: response.statusCode, details: data);
    }
    return ApiException('Impossible de joindre le serveur', details: error);
  }

  @override
  String toString() => message;
}
