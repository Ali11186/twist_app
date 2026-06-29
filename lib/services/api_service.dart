import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.twistmena.com/music';
  
  static final http.Client _client = http.Client();
  
  static String _generateSessionId() {
    final random = Random();
    return '${random.nextInt(0xffffffff)}-${random.nextInt(0xffff)}-${random.nextInt(0xffff)}-${random.nextInt(0xffff)}-${random.nextInt(0xffffffffffff)}';
  }
  
  static Map<String, String> get baseHeaders => {
    'user-agent': 'Twist-Mobile/10.10.49 (Android; 12; SM-A217F; music; ar-AE)',
    'app_version': '10.10.49',
    'appversion': '10.10.49',
    'channel': 'mobileapp',
    'content-type': 'application/json',
    'platform': 'android',
    'accept': 'application/json',
    'accept-language': 'ar',
    'host': 'api.twistmena.com',
    'device_id': 'SP1A.210812.016',
    'tgdeviceid': '',
    'device_token': '',
    'tg-token': '',
    'tg-refresh-token': '',
    'access-token': '',
    'sessionid': _generateSessionId(),
    'accept-encoding': 'gzip',
    'connection': 'keep-alive',
  };

  // إرسال كود التحقق
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final headers = Map<String, String>.from(baseHeaders);
      final response = await _client.post(
        Uri.parse('$baseUrl/Dlogin/sendCode'),
        headers: headers,
        body: jsonEncode({'dial': phone}),
      );
      return {
        'success': response.statusCode == 200,
        'data': response.statusCode == 200 ? jsonDecode(response.body) : null,
        'message': response.statusCode == 200 ? 'تم إرسال الكود' : response.body,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // التحقق من OTP وتسجيل الدخول
  static Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final headers = Map<String, String>.from(baseHeaders);
      final response = await _client.post(
        Uri.parse('$baseUrl/Dlogin/verify'),
        headers: headers,
        body: jsonEncode({
          'dial': phone,
          'verifyCode': code,
          'socialServiceName': '',
          'socialServiceToken': '',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authHeader = response.headers['authorization'] ?? '';
        final token = authHeader.replaceAll('Bearer ', '');
        
        return {
          'success': true,
          'token': token.isNotEmpty ? token : data['token'] ?? '',
          'data': data,
          'headers': {
            'access-token': data['accessToken'] ?? '',
            'tg-token': data['tgToken'] ?? data['tg_token'] ?? '',
            'tg-refresh-token': data['tgRefreshToken'] ?? data['tg_refresh_token'] ?? '',
            'tgdeviceid': data['tgDeviceId'] ?? data['tg_device_id'] ?? '22821093',
          },
        };
      }
      return {'success': false, 'message': 'رمز التحقق غير صحيح'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // جلب الرصيد
  static Future<int> getBalance(Map<String, String> headers) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/user/loyalty/balance/details'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) return data['balance'] ?? 0;
        if (data is List && data.isNotEmpty) return data[0]['balance'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  // جلب المهام
  static Future<List<Map<String, dynamic>>> getAchievements(Map<String, String> headers) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/user/loyalty/achievements/v2'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> tasks = [];
        
        List categories = [];
        if (data is Map) {
          categories = data['badges'] ?? [];
        } else if (data is List) {
          categories = data;
        }
        
        for (var category in categories) {
          if (category is Map) {
            List badges = category['badges'] ?? [];
            for (var badge in badges) {
              if (badge is Map && badge['rewarded'] != true) {
                tasks.add(Map<String, dynamic>.from(badge));
              }
            }
          }
        }
        return tasks;
      }
    } catch (_) {}
    return [];
  }

  // إنجاز مهمة محددة
  static Future<bool> completeTask(String taskId, Map<String, String> headers) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/loyalty/action/$taskId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // إنجاز جميع المهام
  static Future<int> completeAllTasks(Map<String, String> headers) async {
    int completed = 0;
    final tasks = await getAchievements(headers);
    
    for (var task in tasks) {
      final taskId = task['id']?.toString() ?? '';
      if (taskId.isNotEmpty) {
        final success = await completeTask(taskId, headers);
        if (success) completed++;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    return completed;
  }

  // السحب
  static Future<bool> redeemUnits(String code, Map<String, String> headers) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/loyalty/redeem/$code'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // جلب بيانات البروفايل
  static Future<Map<String, String>> getProfileTokens(Map<String, String> headers, String apiToken) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/register/getProfile?api_token=$apiToken'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          return {
            'tg-token': data['tgToken'] ?? data['tg_token'] ?? '',
            'tg-refresh-token': data['tgRefreshToken'] ?? data['tg_refresh_token'] ?? '',
            'tgdeviceid': data['tgDeviceId'] ?? data['tg_device_id'] ?? '',
          };
        }
      }
    } catch (_) {}
    return {};
  }
}
