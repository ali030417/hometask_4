
class ApiException implements Exception {
  final String massage;

  ApiException(this.massage);

  @override
  String toString() => 'ApiException(massage: $massage)';
}
