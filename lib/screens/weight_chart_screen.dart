import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class WeightChartScreen extends StatefulWidget {
  final int userId;
  const WeightChartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<WeightChartScreen> createState() => _WeightChartScreenState();
}

class _WeightChartScreenState extends State<WeightChartScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> weights = [];
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  final DateFormat hourFormat = DateFormat('HH:mm');
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _loadWeights();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWeights() async {
    final w = await DBHelper.getWeights(widget.userId);
    if (!mounted) return;
    setState(() {
      weights = w.reversed.toList();
      isLoading = false;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Biểu đồ cân nặng'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)))
          : weights.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadWeights,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          _buildChartCard(),
                          const SizedBox(height: 16),
                          _buildDateCard(),
                          const SizedBox(height: 24),
                          _buildStatsCard(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dữ liệu cân nặng',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm dữ liệu cân nặng đầu tiên!',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiến trình cân nặng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (_, __) => CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _WeightChartPainter(weights, hourFormat, _animation.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    final dates = weights
        .map((e) => DateTime.parse(e['date']))
        .map((dt) => dateFormat.format(dt))
        .toSet()
        .toList()
      ..sort();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: Text(
        "Ngày đo: ${dates.join(', ')}",
        style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatsCard() {
    final startWeight = weights.first['weight'] * 1.0;
    final currentWeight = weights.last['weight'] * 1.0;
    final diffWeight = currentWeight - startWeight;

    IconData trendIcon;
    Color trendColor;
    String diffText;

    if (diffWeight > 0) {
      trendIcon = Icons.trending_up;
      trendColor = Colors.red.shade400;
      diffText = "+${diffWeight.toStringAsFixed(1)} kg";
    } else if (diffWeight < 0) {
      trendIcon = Icons.trending_down;
      trendColor = Colors.green.shade400;
      diffText = "${diffWeight.toStringAsFixed(1)} kg";
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = Colors.grey.shade500;
      diffText = "0 kg";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(trendIcon, color: trendColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thay đổi cân nặng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A2C7D),
                      ),
                    ),
                    Text(
                      diffText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(startWeight.toStringAsFixed(1), 'Ban đầu', Icons.flag),
              const SizedBox(width: 24),
              _buildStatItem(currentWeight.toStringAsFixed(1), 'Hiện tại', Icons.person),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6B3FA0)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C7D),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B3FA0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> weights;
  final DateFormat hourFormat;
  final double animValue;

  _WeightChartPainter(this.weights, this.hourFormat, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;

    final rect = Offset.zero & size;
    final RRect containerRRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(12),
    );

    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.9),
        Offset(0, size.height * 0.1),
        [Colors.white, Colors.blue.shade50],
      );
    canvas.drawRRect(containerRRect, gradientPaint);

    final borderPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(containerRRect.deflate(1), borderPaint);

    final double maxWeight =
        weights.map<double>((e) => e['weight'] * 1.0).reduce(math.max);
    final double minWeight =
        weights.map<double>((e) => e['weight'] * 1.0).reduce(math.min);
    double range = maxWeight - minWeight;
    if (range < 0.1) range += 1.0;

    const double paddingLeft = 40;
    const double paddingTop = 40;
    const double paddingRight = 20;
    const double paddingBottom = 60;
    final contentHeight = size.height - paddingTop - paddingBottom;

    final dx = (weights.length > 1)
        ? (size.width - paddingLeft - paddingRight) / (weights.length - 1)
        : 0.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    // ===== Lưới ngang đều =====
    final int horizontalLines = 5;
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = paddingTop + (i * contentHeight / horizontalLines);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // ===== Line và điểm =====
    final path = Path();
    final gradientPaintLine = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, -20),
        [const Color(0xFF667eea), const Color(0xFF764ba2)],
      )
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < weights.length; i++) {
      final x = paddingLeft + i * dx;
      final weight = weights[i]['weight'] * 1.0;
      final normalizedY = (maxWeight - weight) / range;
      final y = paddingTop + normalizedY * contentHeight;

      final pointX = paddingLeft + (x - paddingLeft) * animValue;

      // Shadow + điểm
      canvas.drawCircle(Offset(pointX, y + 1), 6, shadowPaint);
      canvas.drawCircle(Offset(pointX, y), 6, pointPaint);
      canvas.drawCircle(Offset(pointX, y), 6, Paint()..color = const Color(0xFF667eea));

      // Nhãn cân nặng trên điểm
      textPainter.text = TextSpan(
        text: weight.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2)],
        ),
      );
      textPainter.layout();
      final textX = pointX - textPainter.width / 2;
      final textY = math.max(y - 20 - textPainter.height, paddingTop - 10);
      textPainter.paint(canvas, Offset(textX, textY));

      // Nhãn giờ đo dưới điểm
      final hourText = hourFormat.format(DateTime.parse(weights[i]['date']));
      textPainter.text = TextSpan(
        text: hourText,
        style: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pointX - textPainter.width / 2, y + 12));

      // Line nối điểm
      if (i == 0) path.moveTo(pointX, y);
      else path.lineTo(pointX, y);
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, gradientPaintLine);

    // ===== Trục Y và X =====
    textPainter.text = const TextSpan(
      text: 'Kg',
      style: TextStyle(
        color: Color(0xFF666666),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, paddingTop - 25));

    textPainter.text = const TextSpan(
      text: 'Thời gian',
      style: TextStyle(
        color: Color(0xFF666666),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 60, size.height - 28));
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) => true;
}
