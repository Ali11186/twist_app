import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.twistmena.com/music';

  Map<String, String> _initHeaders() {
    final ip = '102.62.${Random().nextInt(255) + 1}.${Random().nextInt(255) + 1}';
    return {
      'User-Agent': 'Twist-Mobile/11.2.10 (Android; 14; SM-A235F; music; en-GB)',
      'app_version': '11.2.10',
      'appversion': '11.2.10',
      'channel': 'mobileapp',
      'content-type': 'application/json',
      'platform': 'android',
      'accept': 'application/json',
      'accept-language': 'en',
      'host': 'api.twistmena.com',
      'device_id': 'UP1A.231005.007',
      'sessionid': 'f74d51bb-d548-4d5b-835c-3b6fc99076f6',
      'X-Forwarded-For': ip,
      'X-Real-IP': ip,
      'customer-ip': ip,
    };
  }

  String _formatPhone(String phone) {
    String p = phone.trim().replaceAll('+', '').replaceAll(' ', '');
    if (p.startsWith('01')) {
      p = '2' + p;
    }
    return p;
  }

  Future<bool> sendCode(String phone) async {
    final formatted = _formatPhone(phone);
    final headers = _initHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/sendCode'),
        headers: headers,
        body: jsonEncode({'dial': formatted}),
      );

      if (response.statusCode == 200) {
        final body = response.body;
        return !body.contains('Failed');
      }
      return false;
    } catch (e) {
      throw Exception('فشل الاتصال: $e');
    }
  }

  Future<Map<String, dynamic>?> verifyCode(String phone, String code) async {
    final formatted = _formatPhone(phone);
    final headers = _initHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/verify'),
        headers: headers,
        body: jsonEncode({
          'dial': formatted,
          'verifyCode': code,
          'socialServiceName': '',
          'socialServiceToken': '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? token = data['token'] ?? data['authorization'];
        if (token == null) {
          token = response.headers['authorization'];
        }
        if (token != null) {
          token = token.replaceAll('Bearer ', '');
          return {
            'token': token,
            'accessToken': data['accessToken'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      throw Exception('فشل التحقق: $e');
    }
  }

  Future<int> getBalance(String token, String accessToken) async {
    final headers = _initHeaders();
    headers['authorization'] = 'Bearer $token';
    headers['access-token'] = accessToken;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/balance/details'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['balance'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> collectBadges(String token, String accessToken) async {
    final headers = _initHeaders();
    headers['authorization'] = 'Bearer $token';
    headers['access-token'] = accessToken;

    int count = 0;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/achievements/v2'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final badges = data['badges'] ?? [];

        for (final group in badges) {
          for (final item in group['badges'] ?? []) {
            if (item['rewarded'] == false) {
              await http.post(
                Uri.parse('$baseUrl/loyalty/action/${item['id']}'),
                headers: headers,
                body: jsonEncode({}),
              );
              count++;
              await Future.delayed(const Duration(milliseconds: 400));
            }
          }
        }
      }
      return count;
    } catch (e) {
      return count;
    }
  }

  Future<bool> redeem(String code, String token, String accessToken) async {
    final headers = _initHeaders();
    headers['authorization'] = 'Bearer $token';
    headers['access-token'] = accessToken;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loyalty/redeem/$code'),
        headers: headers,
        body: jsonEncode({}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
