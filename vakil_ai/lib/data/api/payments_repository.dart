import 'api_client.dart';

class PaymentsRepository {
  PaymentsRepository(this._client);
  final ApiClient _client;

  Future<String> createCheckoutUrl(String provider) async {
    final json = await _client.post('/payments/checkout-url', {'provider': provider});
    return json['url'] as String;
  }
}
