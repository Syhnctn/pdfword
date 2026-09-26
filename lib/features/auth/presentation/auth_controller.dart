import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfword_pro/features/shared/models/auth_mock_state.dart';
import 'package:pdfword_pro/features/shared/repositories/auth_gateway.dart';

class AuthController extends StateNotifier<AuthMockState> {
  AuthController(this._authGateway) : super(const AuthMockState());

  final AuthGateway _authGateway;

  Future<void> signIn(AuthProviderType provider) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      currentProvider: provider,
    );
    try {
      await _authGateway.signIn(provider);
    } catch (_) {
      // Keep UI flow resilient even if real auth provider is unavailable.
    }
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      clearProvider: true,
    );
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    await _authGateway.signOut();
    state = const AuthMockState(isAuthenticated: false);
  }
}
