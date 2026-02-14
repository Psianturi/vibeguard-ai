import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vibe_models.dart';
import 'vibe_provider.dart';

final txHistoryProvider = FutureProvider.family<List<TxHistoryItem>, String>((ref, userAddress) async {
  final api = ref.read(apiServiceProvider);
  return api.getTxHistory(userAddress: userAddress, limit: 50);
});
