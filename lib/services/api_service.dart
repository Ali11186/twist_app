import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.twistmena.com/music';

  String _generateIp() {
    return '102.62.${Random().nextInt(255) + 1}.${Random().nextInt(255) + 1}';
  }

  Map<String, String> _getHeaders() {
    final ip = _generateIp();
    return {
      'user-agent': 'Twist-Mobile/11.2.10 (Android; 12; SM-A217F; music; ar-AE)',
      'app_version': '11.2.10',
      'appversion': '11.2.10',
      'channel': 'mobileapp',
      'content-type': 'application/json; charset=utf-8',
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
      'sessionid': 'f74d51bb-d548-4d5b-835c-3b6fc99076f6',
      'X-Forwarded-For': ip,
      'X-Real-IP': ip,
      'customer-ip': ip,
      'accept-encoding': 'gzip',
      'connection': 'keep-alive',
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
    final headers = _getHeaders();
    final body = jsonEncode({'dial': formatted});

    print('=== SEND CODE ===');
    print('URL: $baseUrl/Dlogin/sendCode');
    print('Phone formatted: $formatted');
    print('Body: $body');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/sendCode'),
        headers: headers,
        body: body,
        encoding: utf8,
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseBody = response.body.toLowerCase();
        return !responseBody.contains('failed') && 
               !responseBody.contains('error') &&
               !responseBody.contains('invalid');
      }
      return false;
    } catch (e) {
      print('Error sending code: $e');
      throw Exception('فشل الاتصال بالسيرفر: $e');
    }
  }

  Future<Map<String, dynamic>?> verifyCode(String phone, String code) async {
    final formatted = _formatPhone(phone);
    final headers = _getHeaders();
    final body = jsonEncode({
      'dial': formatted,
      'verifyCode': code,
      'socialServiceName': '',
      'socialServiceToken': '',
    });

    print('=== VERIFY CODE ===');
    print('Phone: $formatted');
    print('Code: $code');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/verify'),
        headers: headers,
        body: body,
        encoding: utf8,
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        String? token = data['token'];
        if (token == null) {
          token = data['authorization'];
        }
        if (token == null) {
          final authHeader = response.headers['authorization'] ?? '';
          if (authHeader.startsWith('Bearer ')) {
            token = authHeader.substring(7);
          } else {
            token = authHeader;
          }
        }

        if (token != null && token.isNotEmpty) {
          return {
            'token': token.toString().replaceAll('Bearer ', ''),
            'accessToken': data['accessToken']?.toString() ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error verifying code: $e');
      throw Exception('فشل التحقق: $e');
    }
  }

  Future<int> getBalance(String token, String accessToken) async {
    final headers = _getHeaders();
    headers['authorization'] = 'Bearer $token';
    headers['access-token'] = accessToken;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/loyalty/balance/details'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          return data['balance'] ?? 0;
        } else if (data is List && data.isNotEmpty) {
          return data[0]['balance'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> collectBadges(String token, String accessToken) async {
    final headers = _getHeaders();
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
    final headers = _getHeaders();
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
