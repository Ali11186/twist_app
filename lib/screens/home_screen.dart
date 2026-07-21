import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';
import 'collect_screen.dart';
import 'rewards_screen.dart';
import 'account_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final auth = ref.read(authProvider);
    if (auth.token != null && auth.accessToken != null) {
      await ref.read(loyaltyProvider.notifier).getBalance(auth.token!, auth.accessToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loyalty = ref.watch(loyaltyProvider);

    final screens = [
      _HomeContent(balance: loyalty.balance, phone: auth.phone ?? ''),
      const RewardsScreen(),
      const Center(child: Text('نشاطي', style: TextStyle(color: Colors.white))),
      const AccountScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'الجوائز'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'نشاطي'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final int balance;
  final String phone;
  const _HomeContent({required this.balance, required this.phone});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Row(
                  children: [
                    Text(phone, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundColor: Color(0xFF4ADE80),
                      child: Icon(Icons.person, color: Color(0xFF0D1117)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('رصيدك الحالي', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.star, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(balance.toString(),
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                          const Text('نقطة', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectScreen())),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('تجميع النقاط'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
              icon: const Icon(Icons.redeem),
              label: const Text('استبدال الجوائز'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 24),
            const Text('آخر الأنشطة', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _HistoryItem(action: 'تم تجميع إنجاز', time: 'منذ 2 ساعة', points: '+50', isPositive: true),
            _HistoryItem(action: 'تم استبدال جائزة', time: 'منذ يوم', points: '-100', isPositive: false),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String action, time, points;
  final bool isPositive;
  const _HistoryItem({required this.action, required this.time, required this.points, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(time, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
          Text(points,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: isPositive ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
              )),
        ],
      ),
    );
  }
}
