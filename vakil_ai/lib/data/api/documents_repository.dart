import '../models.dart';
import 'api_client.dart';

class DocumentsRepository {
  DocumentsRepository(this._client);
  final ApiClient _client;

  Future<List<DocumentAnalysis>> list() async {
    final json = await _client.get('/documents') as List;
    return json.map((d) => DocumentAnalysis.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<DocumentAnalysis> get(String id) async {
    final json = await _client.get('/documents/$id');
    return DocumentAnalysis.fromJson(json as Map<String, dynamic>);
  }

  Future<DocumentAnalysis> upload({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final json = await _client.uploadFile(
      '/documents/upload',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return DocumentAnalysis.fromJson(json as Map<String, dynamic>);
  }
}
