import 'package:flutter/material.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _controller,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.4), blurRadius: 60)],
                ),
                child: const Icon(Icons.check, size: 50, color: Color(0xFF0D1117)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('تم الاستبدال بنجاح!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('تمت إضافة الجائزة إلى حسابك بنجاح', style: TextStyle(color: Color(0xFF9CA3AF))),
            const Text('استمتع بخدمات Twist', style: TextStyle(color: Color(0xFF4ADE80))),
            const SizedBox(height: 40),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
