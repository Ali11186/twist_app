import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otpCode = '';
  int _timerSeconds = 45;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) _timerSeconds--;
        });
      }
      return mounted && _timerSeconds > 0;
    });
  }

  void _addDigit(int d) {
    if (_otpCode.length < 6) {
      setState(() => _otpCode += d.toString());
      if (_otpCode.length == 6) _verifyCode();
    }
  }

  void _removeDigit() {
    if (_otpCode.isNotEmpty) {
      setState(() => _otpCode = _otpCode.substring(0, _otpCode.length - 1));
    }
  }

  Future<void> _verifyCode() async {
    final success = await ref.read(authProvider.notifier).verifyCode(_otpCode);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الكود غلط أو انتهت صلاحيته'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Text('أدخل كود التحقق', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('لقد أرسلنا كود التحقق إلى ${widget.phone}',
                  style: const TextStyle(color: Color(0xFF9CA3AF))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      border: Border.all(
                        color: i < _otpCode.length
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF374151),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        i < _otpCode.length ? _otpCode[i] : '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'إعادة إرسال الكود خلال 00:${_timerSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _otpCode.length == 6 ? _verifyCode : null,
                  child: const Text('تأكيد'),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    ...List.generate(9, (i) => _NumButton(
                      label: '${i + 1}',
                      onPressed: () => _addDigit(i + 1),
                    )),
                    const SizedBox.shrink(),
                    _NumButton(label: '0', onPressed: () => _addDigit(0)),
                    _NumButton(label: '⌫', onPressed: _removeDigit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _NumButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
    );
  }
}
