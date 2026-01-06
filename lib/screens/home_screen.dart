import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'add_weight_screen.dart';
import 'profile_screen.dart';
import 'weight_chart_screen.dart';

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
      weights.isNotEmpty ? (weights.first['weight'] as num).toDouble() : null;

  double? get averageWeight {
    if (weights.isEmpty) return null;
    final sum = weights.fold<double>(
      0,
      (t, e) => t + (e['weight'] as num).toDouble(),
    );
    return sum / weights.length;
  }

  double get bmi {
    final height = (profile?['height'] ?? 1.7) as num;
    if (currentWeight == null) return 0;
    return currentWeight! / (height * height);
  }

  String get bmiStatus {
    if (bmi == null || bmi == 0) return '--';
    if (bmi! < 18.5) return 'Gầy';
    if (bmi! < 25) return 'Bình thường';
    if (bmi! < 30) return 'Thừa cân';
    return 'Béo phì';
  }


  Color get bmiColor {
    if (bmi == null || bmi == 0) return Colors.grey;
    if (bmi! < 18.5) return Colors.yellow;
    if (bmi! < 25) return Colors.green;
    if (bmi! < 30) return Colors.orange;
    return Colors.red;
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
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
      backgroundColor: const Color(0xFFF8F9FA),

      /// ================= APPBAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 10),
            const Text(
              'Weight Tracker',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),

      /// ================= FAB =================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add),
        label: const Text('Thêm cân nặng'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddWeightScreen(userId: widget.userId),
            ),
          );
          _loadData();
        },
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== HEADER (FIX OVERFLOW)  =====
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: currentWeight == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.analytics_outlined,
                                size: 64,
                                color: Colors.white70,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Chưa có dữ liệu cân nặng',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cân nặng hiện tại',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${currentWeight!.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayFormat.format(
                                  DateTime.parse(weights.first['date']),
                                ),
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            /// ===== INFO CARDS =====
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    'Trung bình',
                    averageWeight == null
                        ? '--'
                        : '${averageWeight!.toStringAsFixed(1)} kg',
                    Icons.analytics_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    'BMI',
                    bmi.toStringAsFixed(1),
                    Icons.monitor_weight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    'Trạng thái',
                    bmiStatus,
                    Icons.favorite,
                    color: bmiColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ===== CHART BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.show_chart),
                label: const Text(
                  'Xem biểu đồ cân nặng',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WeightChartScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            /// ===== HISTORY TITLE =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử cân nặng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${weights.length} lần',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ===== HISTORY LIST =====
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weights.length,
              itemBuilder: (_, index) {
                final item = weights[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.scale, color: Color(0xFF667eea)),
                    title: Text(
                      '${(item['weight'] as num).toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      displayFormat.format(
                        DateTime.parse(item['date']),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xóa dữ liệu'),
                            content: const Text('Bạn có chắc muốn xóa?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await DBHelper.deleteWeight(item['id']);
                          _loadData();
                        }
                      },
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

  Widget _infoCard(
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color ?? const Color(0xFF667eea)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color ?? const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
