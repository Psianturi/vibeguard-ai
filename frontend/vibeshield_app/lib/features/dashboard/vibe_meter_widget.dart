import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import '../../models/vibe_models.dart';

class ScanningVibeMeterWidget extends StatefulWidget {
  const ScanningVibeMeterWidget({super.key});

  @override
  State<ScanningVibeMeterWidget> createState() => _ScanningVibeMeterWidgetState();
}

class _ScanningVibeMeterWidgetState extends State<ScanningVibeMeterWidget> {
  final _rng = Random();
  Timer? _timer;
  double _value = 50;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final next = 50 + (_rng.nextDouble() * 60 - 30); // 20..80-ish
      setState(() => _value = next.clamp(0, 100));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Vibe Meter', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _value,
                      color: Colors.orange,
                      title: '${_value.toStringAsFixed(0)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 100 - _value,
                      color: Colors.grey.shade800,
                      title: '',
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning Social Signals…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class VibeMeterWidget extends StatelessWidget {
  final VibeCheckResult result;

  const VibeMeterWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Vibe Meter', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: result.sentiment.score,
                      color: _getVibeColor(result.sentiment.score),
                      title: '${result.sentiment.score.toStringAsFixed(0)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 100 - result.sentiment.score,
                      color: Colors.grey.shade800,
                      title: '',
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getVibeText(result.sentiment.score),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Price: \$${result.price.price.toStringAsFixed(2)}'),
            Text('24h Change: ${result.price.priceChange24h.toStringAsFixed(2)}%'),
          ],
        ),
      ),
    );
  }

  Color _getVibeColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getVibeText(double score) {
    if (score >= 70) return '✨ Good Vibes';
    if (score >= 40) return '⚠️ Neutral Vibes';
    return '🚨 Bad Vibes';
  }
}
