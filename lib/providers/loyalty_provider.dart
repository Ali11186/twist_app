import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class LoyaltyState {
  final int balance;
  final List<dynamic> badges;
  final List<dynamic> history;
  final bool isLoading;
  final String? error;

  const LoyaltyState({
    this.balance = 0,
    this.badges = const [],
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  LoyaltyState copyWith({
    int? balance,
    List<dynamic>? badges,
    List<dynamic>? history,
    bool? isLoading,
    String? error,
  }) {
    return LoyaltyState(
      balance: balance ?? this.balance,
      badges: badges ?? this.badges,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier() : super(const LoyaltyState());

  final ApiService _api = ApiService();

  Future<void> getBalance(String token, String accessToken) async {
    state = state.copyWith(isLoading: true);
    try {
      final balance = await _api.getBalance(token, accessToken);
      state = state.copyWith(balance: balance, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<int> collectBadges(String token, String accessToken) async {
    state = state.copyWith(isLoading: true);
    try {
      final count = await _api.collectBadges(token, accessToken);
      final balance = await _api.getBalance(token, accessToken);
      state = state.copyWith(balance: balance, isLoading: false);
      return count;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 0;
    }
  }

  Future<bool> redeem(String code, String token, String accessToken) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _api.redeem(code, token, accessToken);
      if (success) {
        final balance = await _api.getBalance(token, accessToken);
        state = state.copyWith(balance: balance, isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier();
});
