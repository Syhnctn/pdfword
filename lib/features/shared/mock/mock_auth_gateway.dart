import 'package:pdfword_pro/features/shared/models/auth_mock_state.dart';
import 'package:pdfword_pro/features/shared/repositories/auth_gateway.dart';

class MockAuthGateway implements AuthGateway {
  @override
  Future<void> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
