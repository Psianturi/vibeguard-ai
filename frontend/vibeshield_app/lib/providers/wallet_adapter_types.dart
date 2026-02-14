class WalletConnection {
  final String address;
  final int chainId;

  const WalletConnection({required this.address, required this.chainId});
}

abstract class WalletAdapter {
  bool get isSupported;

  Future<WalletConnection> connect();

  void disconnect();
}
