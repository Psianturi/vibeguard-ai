import 'wallet_adapter_types.dart';

class StubWalletAdapter implements WalletAdapter {
  @override
  bool get isSupported => false;

  @override
  Future<WalletConnection> connect() async {
    throw UnsupportedError(
        'Wallet connection is only supported on Flutter Web.');
  }

  @override
  void disconnect() {
  }
}

WalletAdapter createWalletAdapter() => StubWalletAdapter();
