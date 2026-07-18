import '../models.dart';
import 'api_client.dart';

class ChatRepository {
  ChatRepository(this._client);
  final ApiClient _client;

  Future<List<ChatMessage>> list(String documentId) async {
    final json = await _client.get('/documents/$documentId/chat') as List;
    return json.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> send(String documentId, String text) async {
    final json = await _client.post('/documents/$documentId/chat', {'text': text}) as List;
    return json.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }
}
