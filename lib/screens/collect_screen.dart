import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';

class CollectScreen extends ConsumerStatefulWidget {
  const CollectScreen({super.key});

  @override
  ConsumerState<CollectScreen> createState() => _CollectScreenState();
}

class _CollectScreenState extends ConsumerState<CollectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0;
  int _collected = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _startCollection();
  }

  Future<void> _startCollection() async {
    final auth = ref.read(authProvider);
    if (auth.token == null || auth.accessToken == null) return;

    _controller.addListener(() {
      setState(() => _progress = _controller.value * 0.65);
    });
    _controller.forward();

    final count = await ref.read(loyaltyProvider.notifier).collectBadges(auth.token!, auth.accessToken!);

    setState(() {
      _collected = count;
      _isComplete = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تجميع $count إنجاز جديد!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200, height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFF1F2937),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
                  ),
                  Text('${(_progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('جاري تجميع النقاط', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('يرجى الانتظار بينما نقوم بجمع الإنجازات المتاحة لك',
                style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(height: 8),
            Text('$_collected / 40 إنجاز تم تجميعه',
                style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w600)),
            if (_isComplete) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تسجيل الدخول اليومي', style: TextStyle(color: Colors.white)),
                        Text('+10 نقطة', style: TextStyle(color: Color(0xFF4ADE80))),
                      ],
                    ),
                    Icon(Icons.check_circle, color: Color(0xFF4ADE80)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
