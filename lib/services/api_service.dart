import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.twistmena.com/music';

  String _generateSessionId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (match) {
        final r = Random().nextInt(16);
        final v = match[0] == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    );
  }

  String _generateIp() {
    return '102.62.${Random().nextInt(255) + 1}.${Random().nextInt(255) + 1}';
  }

  Map<String, String> _initHeaders() {
    final ip = _generateIp();
    final sessionId = _generateSessionId();
    return {
      'User-Agent': 'Twist-Mobile/11.2.10 (Android; 14; SM-A235F; music; en-GB)',
      'app_version': '11.2.10',
      'appversion': '11.2.10',
      'channel': 'mobileapp',
      'content-type': 'application/json',
      'platform': 'android',
      'accept': 'application/json',
      'accept-language': 'ar',
      'host': 'api.twistmena.com',
      'device_id': 'UP1A.231005.007',
      'sessionid': sessionId,
      'X-Forwarded-For': ip,
      'X-Real-IP': ip,
      'customer-ip': ip,
      'tgdeviceid': '',
      'device_token': '',
      'tg-token': '',
      'tg-refresh-token': '',
      'access-token': '',
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
    final headers = _initHeaders();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Dlogin/sendCode'),
        headers: headers,
        body: jsonEncode({'dial': formatted}),
      );

      print('SendCode Response: ${response.statusCode}');
      print('SendCode Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = response.body;
        return !body.toLowerCase().contains('failed');
      }
      return false;
    } catch (e) {
      print('SendCode Error: $e');
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

      print('Verify Response: ${response.statusCode}');
      print('Verify Body: ${response.body}');
      print('Verify Headers: ${response.headers}');

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
      print('Verify Error: $e');
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
