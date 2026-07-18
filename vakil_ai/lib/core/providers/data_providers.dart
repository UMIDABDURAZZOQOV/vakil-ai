import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/api/api_client.dart';
import '../../data/api/auth_repository.dart';
import '../../data/api/chat_repository.dart';
import '../../data/api/documents_repository.dart';
import '../../data/api/payments_repository.dart';
import '../../data/models.dart';

const _tokenStorageKey = 'vakil_ai_access_token';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

class AuthTokenNotifier extends StateNotifier<String?> {
  AuthTokenNotifier(this._storage) : super(null) {
    _restore();
  }

  final FlutterSecureStorage _storage;

  Future<void> _restore() async {
    state = await _storage.read(key: _tokenStorageKey);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenStorageKey, value: token);
    state = token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenStorageKey);
    state = null;
  }
}

final authTokenProvider = StateNotifierProvider<AuthTokenNotifier, String?>(
  (ref) => AuthTokenNotifier(ref.watch(secureStorageProvider)),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(() => ref.read(authTokenProvider));
});

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final documentsRepositoryProvider = Provider((ref) => DocumentsRepository(ref.watch(apiClientProvider)));
final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.watch(apiClientProvider)));
final paymentsRepositoryProvider = Provider((ref) => PaymentsRepository(ref.watch(apiClientProvider)));

/// Null when logged out; loading/error states surface through AsyncValue.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return null;
  return ref.watch(authRepositoryProvider).getMe();
});

final documentsListProvider = FutureProvider.autoDispose<List<DocumentAnalysis>>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return const [];
  return ref.watch(documentsRepositoryProvider).list();
});

final documentDetailProvider = FutureProvider.autoDispose.family<DocumentAnalysis, String>((ref, id) async {
  return ref.watch(documentsRepositoryProvider).get(id);
});

final chatHistoryProvider = FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, documentId) async {
  return ref.watch(chatRepositoryProvider).list(documentId);
});
