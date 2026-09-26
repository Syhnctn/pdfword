enum AuthProviderType {
  apple,
  google,
  email,
}

class AuthMockState {
  const AuthMockState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.currentProvider,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final AuthProviderType? currentProvider;

  AuthMockState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AuthProviderType? currentProvider,
    bool clearProvider = false,
  }) {
    return AuthMockState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentProvider: clearProvider
          ? null
          : (currentProvider ?? this.currentProvider),
    );
  }
}
