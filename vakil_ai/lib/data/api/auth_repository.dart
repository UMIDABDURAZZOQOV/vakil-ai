import '../models.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<String> register({required String identifier, required String password, String name = ''}) async {
    final json = await _client.post('/auth/register', {
      'identifier': identifier,
      'password': password,
      'name': name,
    });
    return json['access_token'] as String;
  }

  Future<String> login({required String identifier, required String password}) async {
    final json = await _client.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    return json['access_token'] as String;
  }

  Future<AppUser> getMe() async {
    final json = await _client.get('/users/me');
    return AppUser.fromJson(json as Map<String, dynamic>);
  }
}
