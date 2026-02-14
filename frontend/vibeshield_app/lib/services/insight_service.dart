import 'package:dio/dio.dart';
import '../core/config.dart';
import '../models/insight_models.dart';

class InsightService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<Map<String, TokenInsight>> getMultiTokenInsights({
    List<String>? tokens,
    String window = 'Daily',
  }) async {
    try {
      final response = await _dio.post(
        AppConfig.vibeMultiEndpoint,
        data: {
          'tokens': tokens ?? ['BTC', 'BNB', 'ETH', 'SOL'],
          'window': window,
        },
      );

      final data = response.data;
      final tokensData = data['tokens'] as Map<String, dynamic>;
      
      final result = <String, TokenInsight>{};
      tokensData.forEach((key, value) {
        result[key] = TokenInsight.fromJson({
          'token': key,
          'window': window,
          ...value as Map<String, dynamic>,
        });
      });

      return result;
    } catch (e) {
      throw Exception('Failed to load insights: $e');
    }
  }

  Future<TokenInsight> getSingleTokenInsight({
    required String token,
    String window = 'Daily',
  }) async {
    try {
      final response = await _dio.post(
        AppConfig.vibeInsightsEndpoint,
        data: {'token': token, 'window': window},
      );

      final data = response.data;
      return TokenInsight.fromJson({
        'token': token,
        'window': window,
        ...data['enhanced'] as Map<String, dynamic>,
      });
    } catch (e) {
      throw Exception('Failed to load insight for $token: $e');
    }
  }

  Future<List<ChainInfo>> getChains() async {
    try {
      final response = await _dio.get(AppConfig.vibeChainsEndpoint);
      final data = response.data;
      final chains = (data['chains'] as List)
          .map((e) => ChainInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      return chains;
    } catch (e) {
      throw Exception('Failed to load chains: $e');
    }
  }
}
