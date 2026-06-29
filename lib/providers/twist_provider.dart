import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/redeem_option.dart';

class TwistProvider extends ChangeNotifier {
  Map<String, String> _headers = {};
  bool _isLoading = false;
  String _phone = '';
  int _balance = 0;
  String _statusMessage = '';
  List<String> _completedTasks = [];
  List<RedeemOption> _availableOptions = [];
  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;
  int get balance => _balance;
  String get statusMessage => _statusMessage;
  List<String> get completedTasks => _completedTasks;
  List<RedeemOption> get availableOptions => _availableOptions;
  bool get isLoggedIn => _isLoggedIn;

  void setPhone(String phone) {
    _phone = phone;
    notifyListeners();
  }

  // إرسال OTP
  Future<bool> sendOtp() async {
    _isLoading = true;
    _statusMessage = 'جاري إرسال رمز التحقق...';
    notifyListeners();

    String formattedPhone = _phone;
    if (_phone.startsWith('01')) {
      formattedPhone = '2$_phone';
    } else if (_phone.startsWith('+2')) {
      formattedPhone = _phone.substring(1);
    } else {
      formattedPhone = _phone.replaceAll('+', '').replaceAll(' ', '');
    }

    final result = await ApiService.sendOtp(formattedPhone);
    
    _isLoading = false;
    _statusMessage = result['success'] ? '✅ تم إرسال رمز التحقق' : '❌ ${result['message']}';
    notifyListeners();
    
    return result['success'] == true;
  }

  // التحقق من OTP
  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    _statusMessage = 'جاري التحقق من الرمز...';
    notifyListeners();

    String formattedPhone = _phone;
    if (_phone.startsWith('01')) {
      formattedPhone = '2$_phone';
    } else if (_phone.startsWith('+2')) {
      formattedPhone = _phone.substring(1);
    } else {
      formattedPhone = _phone.replaceAll('+', '').replaceAll(' ', '');
    }

    final result = await ApiService.verifyOtp(formattedPhone, code);
    
    if (result['success'] == true) {
      _headers = Map<String, String>.from(ApiService.baseHeaders);
      _headers['authorization'] = 'Bearer ${result['token']}';
      
      Map<String, String> extraHeaders = Map<String, String>.from(result['headers'] ?? {});
      _headers.addAll(extraHeaders);
      
      _isLoggedIn = true;
      _statusMessage = '✅ تم تسجيل الدخول بنجاح';
      
      // جلب الرصيد
      _balance = await ApiService.getBalance(_headers);
    } else {
      _statusMessage = '❌ ${result['message']}';
    }
    
    _isLoading = false;
    notifyListeners();
    
    return result['success'] == true;
  }

  // إنجاز جميع المهام
  Future<void> completeAllTasks() async {
    _isLoading = true;
    _statusMessage = 'جاري إنجاز المهام...';
    _completedTasks = [];
    notifyListeners();

    int initialBalance = _balance;
    
    // تكرار 4 مرات مثل السكريبت
    for (int attempt = 0; attempt < 4; attempt++) {
      _statusMessage = '🔄 المحاولة ${attempt + 1}/4...';
      notifyListeners();
      
      int completed = await ApiService.completeAllTasks(_headers);
      _completedTasks.add('المحاولة ${attempt + 1}: تم إنجاز $completed مهمة');
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // تحديث الرصيد
    _balance = await ApiService.getBalance(_headers);
    int earned = _balance - initialBalance;
    
    _availableOptions = RedeemOption.getAvailableOptions(_balance);
    
    _statusMessage = '🟢 الكوينز المكتسبة: +$earned كوينز\n💰 الرصيد الحالي: $_balance كوينز';
    _isLoading = false;
    notifyListeners();
  }

  // سحب وحدات
  Future<bool> redeemUnits(RedeemOption option) async {
    _isLoading = true;
    _statusMessage = 'جاري سحب ${option.units} وحدة...';
    notifyListeners();

    final success = await ApiService.redeemUnits(option.code, _headers);
    
    if (success) {
      _balance = await ApiService.getBalance(_headers);
      _statusMessage = '✅ تم السحب بنجاح! (+${option.units} وحدة)';
      _availableOptions = RedeemOption.getAvailableOptions(_balance);
    } else {
      _statusMessage = '❌ فشل السحب';
    }
    
    _isLoading = false;
    notifyListeners();
    
    return success;
  }

  void reset() {
    _headers = {};
    _isLoading = false;
    _phone = '';
    _balance = 0;
    _statusMessage = '';
    _completedTasks = [];
    _availableOptions = [];
    _isLoggedIn = false;
    notifyListeners();
  }
}
