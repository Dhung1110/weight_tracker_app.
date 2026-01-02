import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'add_weight_screen.dart';
import 'profile_screen.dart';
import 'weight_chart_screen.dart'; // import trang biểu đồ

class HomeScreen extends StatefulWidget {
  final int userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> weights = [];
  Map<String, dynamic>? profile;
  bool isLoading = true;

  final DateFormat displayFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final w = await DBHelper.getWeights(widget.userId);
    final p = await DBHelper.getProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      weights = w;
      profile = p;
      isLoading = false;
    });
  }

  double? get currentWeight =>
      weights.isNotEmpty ? weights.first['weight'] * 1.0 : null;

  double? get averageWeight {
    if (weights.isEmpty) return null;
    final sum = weights.fold<double>(0, (t, e) => t + e['weight']);
    return sum / weights.length;
  }

  double get bmi {
    final height = profile?['height'] ?? 1.7;
    if (currentWeight == null) return 0;
    return currentWeight! / (height * height);
  }

  String get bmiStatus {
    if (bmi < 18.5) return 'Gầy';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      /// ===== APPBAR (GIỮ LOGO) =====
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 50,
              height: 50,
            ),
            const SizedBox(width: 8),
            const Text('Weight Tracker'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: widget.userId),
              ),
            );
            _loadData();
          },
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
      ),

      /// ===== FLOATING BUTTON CHO THÊM CÂN NẶNG =====
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddWeightScreen(userId: widget.userId),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: currentWeight == null
                  ? const Text(
                      'Chưa có dữ liệu cân nặng',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cân nặng hiện tại',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          '${currentWeight!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayFormat.format(
                            DateTime.parse(weights.first['date']),
                          ),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            /// ===== INFO CARDS =====
            Row(
              children: [
                _infoCard(
                    'Trung bình',
                    averageWeight == null
                        ? '--'
                        : '${averageWeight!.toStringAsFixed(1)} kg',
                    Icons.analytics),
                const SizedBox(width: 12),
                _infoCard('BMI', bmi.toStringAsFixed(1), Icons.monitor_weight),
                const SizedBox(width: 12),
                _infoCard('Trạng thái', bmiStatus, Icons.favorite),
              ],
            ),

            const SizedBox(height: 24),

            /// ===== BUTTON XEM BIỂU ĐỒ =====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WeightChartScreen(userId: widget.userId),
                  ),
                );
              },
              icon: const Icon(Icons.show_chart),
              label: const Text('Xem biểu đồ cân nặng'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
            ),

            const SizedBox(height: 24),

            /// ===== HISTORY =====
            const Text(
              'Lịch sử cân nặng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weights.length,
              itemBuilder: (_, index) {
                final current = weights[index];
                double? diff;

                if (index < weights.length - 1) {
                  diff = current['weight'] - weights[index + 1]['weight'];
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    title: Text(
                      '${current['weight']} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      displayFormat.format(DateTime.parse(current['date'])),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (diff != null && diff != 0)
                          Icon(
                            diff > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: diff > 0 ? Colors.red : Colors.green,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DBHelper.deleteWeight(current['id']);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
