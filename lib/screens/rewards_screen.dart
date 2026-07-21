import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';
import 'success_screen.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  final List<Map<String, dynamic>> _packages = const [
    {'c': 100, 'id': 'EAND_50_UNITS_ID_9', 'n': '50 وحدة', 'pts': 100},
    {'c': 200, 'id': 'EAND_100_UNITS_ID_10', 'n': '100 وحدة', 'pts': 200},
    {'c': 300, 'id': 'EAND_150_UNITS_ID_11', 'n': '150 وحدة', 'pts': 300},
    {'c': 600, 'id': 'EAND_300_UNITS_ID_12', 'n': '300 وحدة', 'pts': 600},
    {'c': 1000, 'id': 'EAND_500_UNITS_ID_13', 'n': '500 وحدة', 'pts': 1000},
    {'c': 1500, 'id': 'EAND_750_UNITS_ID_14', 'n': '750 وحدة', 'pts': 1500},
    {'c': 2000, 'id': 'EAND_1000_UNITS_ID_15', 'n': '1000 وحدة', 'pts': 2000},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyalty = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الجوائز المتاحة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رصيدك: ${loyalty.balance} نقطة', style: const TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _packages.length,
                itemBuilder: (context, index) {
                  final pkg = _packages[index];
                  final canRedeem = loyalty.balance >= pkg['c'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      border: Border.all(color: const Color(0xFF374151)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pkg['n'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text('${pkg['pts']} نقطة', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: canRedeem ? () => _redeem(context, ref, pkg['id']) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canRedeem ? const Color(0xFF4ADE80) : const Color(0xFF374151),
                            foregroundColor: canRedeem ? const Color(0xFF0D1117) : const Color(0xFF6B7280),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(canRedeem ? 'استبدال' : 'غير متاح'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, String code) async {
    final auth = ref.read(authProvider);
    if (auth.token == null || auth.accessToken == null) return;

    final success = await ref.read(loyaltyProvider.notifier).redeem(code, auth.token!, auth.accessToken!);

    if (success && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SuccessScreen()));
    }
  }
}
