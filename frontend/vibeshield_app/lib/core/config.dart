class AppConfig {
  static const String walletConnectProjectId = String.fromEnvironment(
    'WALLETCONNECT_PROJECT_ID',
    defaultValue: '',
  );

  static String get _apiOrigin {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    // Default to the deployed backend for all platforms (Web + Mobile).
    return 'https://vibeguard-ai-production.up.railway.app';
  }

  static String get apiBaseUrl => '$_apiOrigin/api';
  static const String vibeCheckEndpoint = '/vibe/check';
  static const String executeSwapEndpoint = '/vibe/execute-swap';

  // Endpoints for enhanced Cryptoracle data
  static const String vibeInsightsEndpoint = '/vibe/insights';
  static const String vibeMultiEndpoint = '/vibe/multi';
  static const String vibeChainsEndpoint = '/vibe/chains';

  static const String marketPricesEndpoint = '/vibe/prices';

  static const String txHistoryEndpoint = '/vibe/tx-history';
  
  static const String rpcUrl = String.fromEnvironment(
    'RPC_URL',
    defaultValue: 'https://bsc-dataseed.binance.org/',
  );

  static const int chainId = int.fromEnvironment('CHAIN_ID', defaultValue: 56);

  static String get explorerTxBaseUrl {
    const env = String.fromEnvironment('EXPLORER_TX_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    if (chainId == 11155111) return 'https://sepolia.etherscan.io/tx/';
    if (chainId == 56) return 'https://bscscan.com/tx/';
    return '';
  }
}
