import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/insight_service.dart';
import '../models/insight_models.dart';

final insightServiceProvider = Provider((ref) => InsightService());

final multiTokenInsightsProvider = FutureProvider.family<Map<String, TokenInsight>, String>((ref, window) async {
  final service = ref.read(insightServiceProvider);
  return await service.getMultiTokenInsights(window: window);
});

final singleTokenInsightProvider = FutureProvider.family<TokenInsight, Map<String, String>>((ref, params) async {
  final service = ref.read(insightServiceProvider);
  return await service.getSingleTokenInsight(
    token: params['token']!,
    window: params['window'] ?? 'Daily',
  );
});

final chainsProvider = FutureProvider<List<ChainInfo>>((ref) async {
  final service = ref.read(insightServiceProvider);
  return await service.getChains();
});
