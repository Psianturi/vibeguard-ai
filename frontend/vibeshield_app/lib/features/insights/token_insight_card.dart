import 'package:flutter/material.dart';
import '../../models/insight_models.dart';

class TokenInsightCard extends StatelessWidget {
  final TokenInsight insight;
  final VoidCallback? onTap;

  const TokenInsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vibeColor = _getVibeColor(insight.vibeScore);

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        insight.token,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (insight.isFallback) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Demo data',
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: vibeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: vibeColor),
                    ),
                    child: Text(
                      insight.vibeLevel,
                      style: TextStyle(
                        color: vibeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Vibe Score
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vibe Score',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${insight.vibeScore.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: vibeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/100',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildMiniGauge(insight.vibeScore, vibeColor),
                ],
              ),
              const SizedBox(height: 16),

              // Community Stats
              Text(
                'Community Activity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    icon: Icons.message,
                    label: 'Messages',
                    value: _formatNumber(insight.community.totalMessages),
                  ),
                  _buildStat(
                    icon: Icons.people,
                    label: 'Users',
                    value: _formatNumber(insight.community.uniqueUsers),
                  ),
                  _buildStat(
                    icon: Icons.trending_up,
                    label: 'Mentions',
                    value: _formatNumber(insight.community.mentions),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Signals
              Text(
                'Sentiment Signals',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSignalChip('Momentum', insight.signals.momentum),
                  _buildSignalChip('Breakout', insight.signals.breakout),
                  _buildSignalChip('Deviation', insight.signals.deviation),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGauge(double score, Color color) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Text(
              '${score.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSignalChip(String label, double value) {
    final isPositive = value > 0;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Chip(
      label: Text(
        '$label ${value >= 0 ? '+' : ''}${(value * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getVibeColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
