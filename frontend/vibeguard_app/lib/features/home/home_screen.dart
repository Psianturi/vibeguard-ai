import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vibe_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/tx_history_provider.dart';
import '../../core/config.dart';
import '../dashboard/vibe_meter_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _tokenController = TextEditingController(text: 'BTC');
  final _tokenIdController = TextEditingController(text: 'bitcoin');
  final _tokenAddressController = TextEditingController(text: '');
  final _amountController = TextEditingController(text: '1');

  bool _isSwapping = false;

  void _applyPreset({required String symbol, required String coinGeckoId}) {
    setState(() {
      _tokenController.text = symbol;
      _tokenIdController.text = coinGeckoId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vibeState = ref.watch(vibeNotifierProvider);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ VibeGuard AI'),
        centerTitle: true,
        actions: [
          if (walletState.isConnected)
            IconButton(
              tooltip: 'Disconnect wallet',
              onPressed: () => ref.read(walletProvider.notifier).disconnect(),
              icon: const Icon(Icons.logout),
            )
          else
            IconButton(
              tooltip: 'Connect wallet',
              onPressed: () => ref.read(walletProvider.notifier).connect(),
              icon: const Icon(Icons.account_balance_wallet),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (walletState.error != null) ...[
                      Text(
                        walletState.error!,
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            walletState.isConnected
                                ? 'Wallet: ${_short(walletState.address ?? '')}\nChainId: ${walletState.chainId ?? '-'}'
                                : (walletState.isSupported ? 'Wallet: not connected' : 'Wallet: not supported'),
                          ),
                        ),
                        if (!walletState.isConnected && walletState.isSupported)
                          ElevatedButton(
                            onPressed: () => ref.read(walletProvider.notifier).connect(),
                            child: const Text('Connect'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('BTC'),
                          selected:
                              _tokenController.text.trim().toUpperCase() ==
                                  'BTC',
                          onSelected: (_) => _applyPreset(
                              symbol: 'BTC', coinGeckoId: 'bitcoin'),
                        ),
                        ChoiceChip(
                          label: const Text('BNB'),
                          selected:
                              _tokenController.text.trim().toUpperCase() ==
                                  'BNB',
                          onSelected: (_) => _applyPreset(
                              symbol: 'BNB', coinGeckoId: 'binancecoin'),
                        ),
                        ChoiceChip(
                          label: const Text('ETH'),
                          selected:
                              _tokenController.text.trim().toUpperCase() ==
                                  'ETH',
                          onSelected: (_) => _applyPreset(
                              symbol: 'ETH', coinGeckoId: 'ethereum'),
                        ),
                        ChoiceChip(
                          label: const Text('USDT'),
                          selected:
                              _tokenController.text.trim().toUpperCase() ==
                                  'USDT',
                          onSelected: (_) => _applyPreset(
                              symbol: 'USDT', coinGeckoId: 'tether'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Token Symbol',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenIdController,
                      decoration: const InputDecoration(
                        labelText: 'CoinGecko ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vibeState.isLoading
                          ? null
                          : () {
                              ref.read(vibeNotifierProvider.notifier).checkVibe(
                                    _tokenController.text,
                                    _tokenIdController.text,
                                  );
                            },
                      child: vibeState.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Check Vibe'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (vibeState.error != null)
              Card(
                color: Colors.red.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(vibeState.error!),
                ),
              ),
            if (vibeState.result != null) ...[
              VibeMeterWidget(result: vibeState.result!),
              const SizedBox(height: 16),
              _buildAnalysisCard(vibeState.result!),
            ],

            if (walletState.isConnected && (walletState.address?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 24),
              _buildEmergencySwapCard(context, walletState.address!),
              const SizedBox(height: 16),
              _buildTxHistoryCard(context, walletState.address!),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySwapCard(BuildContext context, String userAddress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Swap', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenAddressController,
              decoration: const InputDecoration(
                labelText: 'Token Address (ERC20)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (human readable, 18 decimals demo)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSwapping
                    ? null
                    : () async {
                        final tokenAddress = _tokenAddressController.text.trim();
                        final amount = _amountController.text.trim();

                        if (tokenAddress.isEmpty || amount.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token address and amount are required.')),
                          );
                          return;
                        }

                        setState(() => _isSwapping = true);
                        try {
                          final api = ref.read(apiServiceProvider);
                          final result = await api.executeSwap(
                            userAddress: userAddress,
                            tokenAddress: tokenAddress,
                            amount: amount,
                          );

                            if (!context.mounted) return;

                          final txHash = result['txHash'];
                          if (txHash != null && txHash is String && txHash.isNotEmpty) {
                            ref.invalidate(txHistoryProvider(userAddress));
                            final url = AppConfig.explorerTxBaseUrl.isNotEmpty
                                ? '${AppConfig.explorerTxBaseUrl}$txHash'
                                : txHash;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Swap submitted: $url')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Swap result: ${result.toString()}')),
                            );
                          }
                        } catch (e) {
                            if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Swap failed: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _isSwapping = false);
                        }
                      },
                child: _isSwapping
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Execute Emergency Swap (Guardian)'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: This triggers the backend guardian to call the vault. You still need on-chain approval + vault config on the user wallet.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxHistoryCard(BuildContext context, String userAddress) {
    final asyncItems = ref.watch(txHistoryProvider(userAddress));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'On-chain History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(txHistoryProvider(userAddress)),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            asyncItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No transactions recorded yet.');
                }

                return Column(
                  children: items
                      .take(10)
                      .map(
                        (t) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_short(t.txHash)),
                          subtitle: Text(
                            '${DateTime.fromMillisecondsSinceEpoch(t.timestamp).toLocal()} • ${t.source}',
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              final base = AppConfig.explorerTxBaseUrl;
                              final url = base.isNotEmpty ? '$base${t.txHash}' : t.txHash;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(url)),
                              );
                            },
                            child: const Text('Explorer'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load history: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Analysis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Model: ${result.analysis.aiModel}'),
            Text('Risk Score: ${result.analysis.riskScore.toStringAsFixed(1)}'),
            Text(
                'Action: ${result.analysis.shouldExit ? "🚨 EXIT" : "✅ HOLD"}'),
            const SizedBox(height: 8),
            Text(result.analysis.reason),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _tokenIdController.dispose();
    _tokenAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _short(String s) {
    if (s.length <= 12) return s;
    return '${s.substring(0, 6)}...${s.substring(s.length - 4)}';
  }
}
