import 'package:flutter/material.dart';
import '../../models/insight_models.dart';

class ChainSelectorWidget extends StatelessWidget {
  final List<ChainInfo> chains;
  final String? selectedChainId;
  final Function(ChainInfo) onChainSelected;
  
  const ChainSelectorWidget({
    super.key,
    required this.chains,
    this.selectedChainId,
    required this.onChainSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Group chains by network type
    final groupedChains = <String, List<ChainInfo>>{};
    for (final chain in chains) {
      final network = chain.network;
      groupedChains.putIfAbsent(network, () => []).add(chain);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🌐 Select Network', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chains.map((chain) => _buildChainChip(context, chain)).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChainChip(BuildContext context, ChainInfo chain) {
    final theme = Theme.of(context);
    final isSelected = selectedChainId == chain.id;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(chain.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(chain.symbol),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onChainSelected(chain),
      avatar: isSelected 
        ? const Icon(Icons.check, size: 18)
        : null,
    );
  }
}

// Simple token preset data (for chains that don't have API access)
class TokenPreset {
  final String symbol;
  final String coinGeckoId;
  final String network;
  final String icon;
  
  const TokenPreset({
    required this.symbol,
    required this.coinGeckoId,
    required this.network,
    required this.icon,
  });
}

class TokenPresets {
  static const List<TokenPreset> byChain = [
    // Bitcoin
    TokenPreset(symbol: 'BTC', coinGeckoId: 'bitcoin', network: 'Bitcoin', icon: '₿'),
    
    // BNB Chain
    TokenPreset(symbol: 'BNB', coinGeckoId: 'binancecoin', network: 'BNB Chain', icon: 'B'),
    
    // opBNB
    TokenPreset(symbol: 'BNB', coinGeckoId: 'binancecoin', network: 'opBNB', icon: '🔷'),
    
    // Ethereum
    TokenPreset(symbol: 'ETH', coinGeckoId: 'ethereum', network: 'Ethereum', icon: 'Ξ'),
    
    // Solana
    TokenPreset(symbol: 'SOL', coinGeckoId: 'solana', network: 'Solana', icon: '◎'),
    
    // XRP
    TokenPreset(symbol: 'XRP', coinGeckoId: 'ripple', network: 'XRP Ledger', icon: '✕'),
    
    // Dogecoin
    TokenPreset(symbol: 'DOGE', coinGeckoId: 'dogecoin', network: 'Dogecoin', icon: 'Ð'),
    
    // Sui
    TokenPreset(symbol: 'SUI', coinGeckoId: 'sui', network: 'Sui', icon: '⚡'),
    
    // USDT (stablecoin)
    TokenPreset(symbol: 'USDT', coinGeckoId: 'tether', network: 'Multi-chain', icon: '₮'),
  ];
  
  static TokenPreset? findBySymbol(String symbol) {
    try {
      return byChain.firstWhere((p) => p.symbol == symbol.toUpperCase());
    } catch (_) {
      return null;
    }
  }
}
