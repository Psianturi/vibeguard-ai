import 'package:flutter_web3/flutter_web3.dart';

import 'wallet_adapter_types.dart';

class WebWalletAdapter implements WalletAdapter {
  @override
  bool get isSupported => true;

  @override
  Future<WalletConnection> connect() async {
    if (ethereum == null) {
      throw UnsupportedError(
        'MetaMask not detected. Install/enable the MetaMask extension and refresh the page.',
      );
    }

    final accounts = await ethereum!.requestAccount();
    if (accounts.isEmpty) {
      throw Exception('No accounts returned by wallet.');
    }

    final chainId = await ethereum!.getChainId();
    return WalletConnection(address: accounts.first, chainId: chainId);
  }

  @override
  void disconnect() {
  }
}

WalletAdapter createWalletAdapter() => WebWalletAdapter();
