import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet_adapter.dart';

class WalletState {
  final bool isSupported;
  final bool isConnected;
  final String? address;
  final int? chainId;
  final String? error;

  const WalletState({
    required this.isSupported,
    required this.isConnected,
    this.address,
    this.chainId,
    this.error,
  });

  factory WalletState.initial({required bool isSupported}) {
    return WalletState(isSupported: isSupported, isConnected: false);
  }

  WalletState copyWith({
    bool? isSupported,
    bool? isConnected,
    String? address,
    int? chainId,
    String? error,
  }) {
    return WalletState(
      isSupported: isSupported ?? this.isSupported,
      isConnected: isConnected ?? this.isConnected,
      address: address ?? this.address,
      chainId: chainId ?? this.chainId,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier({WalletAdapter? adapter})
      : _adapter = adapter ?? createWalletAdapter(),
        super(const WalletState(isSupported: false, isConnected: false)) {
    state = WalletState.initial(isSupported: _adapter.isSupported);
  }

  final WalletAdapter _adapter;

  Future<void> connect() async {
    if (!_adapter.isSupported) {
      state = state.copyWith(
        isSupported: false,
        isConnected: false,
        error:
            'Wallet connection is supported on Web with MetaMask (window.ethereum).',
      );
      return;
    }

    try {
      final conn = await _adapter.connect();

      state = state.copyWith(
        isSupported: true,
        isConnected: true,
        address: conn.address,
        chainId: conn.chainId,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSupported: true,
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  void disconnect() {
    // Injected wallets can't be truly disconnected programmatically;
    // we just clear local app state.
    _adapter.disconnect();
    state = WalletState.initial(isSupported: _adapter.isSupported);
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});
