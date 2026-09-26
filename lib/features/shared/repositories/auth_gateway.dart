import 'package:pdfword_pro/features/shared/models/auth_mock_state.dart';

abstract class AuthGateway {
  Future<void> signIn(AuthProviderType provider);

  Future<void> signOut();
}
