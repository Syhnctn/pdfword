import 'package:pdfword_pro/features/shared/models/auth_mock_state.dart';
import 'package:pdfword_pro/features/shared/repositories/auth_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealAuthGateway implements AuthGateway {
  RealAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signIn(AuthProviderType provider) async {
    final session = _client.auth.currentSession;
    if (session != null) return;
    try {
      await _client.auth.signInAnonymously();
    } catch (_) {
      // Anonymous provider may be disabled on some projects.
      // Conversion APIs can still work in guest mode when backend allows it.
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
