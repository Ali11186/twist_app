import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthState {
  final String? token;
  final String? phone;
  final String? accessToken;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.phone,
    this.accessToken,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? token,
    String? phone,
    String? accessToken,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      phone: phone ?? this.phone,
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final ApiService _api = ApiService();

  Future<bool> sendCode(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _api.sendCode(phone);
      if (success) {
        state = state.copyWith(phone: phone, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'فشل إرسال الكود');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.verifyCode(state.phone!, code);
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token'] ?? '');
        await prefs.setString('accessToken', result['accessToken'] ?? '');
        await prefs.setString('phone', state.phone!);

        state = state.copyWith(
          token: result['token'],
          accessToken: result['accessToken'],
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'كود غير صحيح');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final accessToken = prefs.getString('accessToken');
    final phone = prefs.getString('phone');
    if (token != null && token.isNotEmpty) {
      state = AuthState(token: token, accessToken: accessToken, phone: phone);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
