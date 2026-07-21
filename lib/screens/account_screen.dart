import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF374151), Color(0xFF1F2937)]),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFF374151), width: 3),
                ),
                child: const Icon(Icons.person, size: 36),
              ),
              const SizedBox(height: 12),
              Text(auth.phone ?? '+20 10 1234 5678', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              _MenuItem(title: 'تاريخ المعاملات', onTap: () {}),
              _MenuItem(title: 'الشروط والأحكام', onTap: () {}),
              _MenuItem(title: 'الخصوصية', onTap: () {}),
              _MenuItem(title: 'تسجيل الخروج', isDanger: true, onTap: () => _logout(context, ref)),
              const Spacer(),
              const Text('الإصدار 1.0.0', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final bool isDanger;
  final VoidCallback onTap;
  const _MenuItem({required this.title, this.isDanger = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 15, color: isDanger ? const Color(0xFFEF4444) : Colors.white)),
            Icon(Icons.arrow_forward_ios, size: 16,
                color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
