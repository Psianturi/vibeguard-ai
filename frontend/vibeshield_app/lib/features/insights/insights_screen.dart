import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insight_provider.dart';
import 'token_insight_card.dart';
import '../wallet/wallet_button.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedWindow = 'Daily';
  final List<String> _windows = ['Daily', '4H', '1H', '15M'];

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(multiTokenInsightsProvider(_selectedWindow));

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Market Insights'),
        actions: [
          const WalletButton(compact: true),
          PopupMenuButton<String>(
            initialValue: _selectedWindow,
            onSelected: (value) {
              setState(() {
                _selectedWindow = value;
              });
            },
            itemBuilder: (context) => _windows
                .map((w) => PopupMenuItem(value: w, child: Text(w)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedWindow, style: const TextStyle(fontSize: 14)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: insightsAsync.when(
        data: (insights) {
          if (insights.isEmpty) {
            return const Center(child: Text('No insights available'));
          }

          // Prioritize BTC, BNB, ETH
          final priority = ['BTC', 'BNB', 'ETH'];
          final sortedKeys = insights.keys.toList()
            ..sort((a, b) {
              final aIndex = priority.indexOf(a);
              final bIndex = priority.indexOf(b);
              if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
              if (aIndex != -1) return -1;
              if (bIndex != -1) return 1;
              return a.compareTo(b);
            });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(multiTokenInsightsProvider(_selectedWindow));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Text(
                  'Real-time sentiment from Cryptoracle',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
                const SizedBox(height: 16),

                // Featured Tokens (BTC, BNB, ETH)
                if (priority.every((t) => insights.containsKey(t))) ...[
                  Text(
                    'Featured',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...priority.map((token) {
                    final insight = insights[token]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TokenInsightCard(
                        insight: insight,
                        onTap: () => _showDetailDialog(context, insight),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Other Tokens
                if (sortedKeys.length > priority.length) ...[
                  Text(
                    'Other Tokens',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedKeys
                      .where((k) => !priority.contains(k))
                      .map((token) {
                    final insight = insights[token]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TokenInsightCard(
                        insight: insight,
                        onTap: () => _showDetailDialog(context, insight),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(multiTokenInsightsProvider(_selectedWindow));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${insight.token} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Vibe Score', '${insight.vibeScore.toStringAsFixed(1)}/100'),
              _buildDetailRow('Positive', '${(insight.sentiment.positive * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Negative', '${(insight.sentiment.negative * 100).toStringAsFixed(1)}%'),
              const Divider(),
              _buildDetailRow('Messages', insight.community.totalMessages.toString()),
              _buildDetailRow('Interactions', insight.community.interactions.toString()),
              _buildDetailRow('Unique Users', insight.community.uniqueUsers.toString()),
              _buildDetailRow('Communities', insight.community.activeCommunities.toString()),
              const Divider(),
              _buildDetailRow('Momentum', '${(insight.signals.momentum * 100).toStringAsFixed(2)}%'),
              _buildDetailRow('Breakout', '${(insight.signals.breakout * 100).toStringAsFixed(2)}%'),
              _buildDetailRow('Deviation', '${(insight.signals.deviation * 100).toStringAsFixed(2)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
