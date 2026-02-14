// ignore_for_file: avoid_web_libraries_in_flutter

import 'wallet_adapter_types.dart';
import 'dart:js_util' as js_util;

Object? _getEthereum() {
  try {
    return js_util.getProperty(js_util.globalThis, 'ethereum');
  } catch (_) {
    return null;
  }
}

Future<List<String>> _requestAccounts(Object ethereum) async {
  final result = await js_util.promiseToFuture(
    js_util.callMethod(
      ethereum,
      'request',
      [js_util.jsify({'method': 'eth_requestAccounts'})],
    ),
  );
  if (result is List) {
    return result.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}

Future<int> _requestChainId(Object ethereum) async {
  final result = await js_util.promiseToFuture(
    js_util.callMethod(
      ethereum,
      'request',
      [js_util.jsify({'method': 'eth_chainId'})],
    ),
  );
  if (result is String) {
    final v = result.trim();
    if (v.startsWith('0x')) {
      return int.parse(v.substring(2), radix: 16);
    }
    return int.tryParse(v) ?? 0;
  }
  return 0;
}

class WebWalletAdapter implements WalletAdapter {
  @override
  bool get isSupported => true;

  @override
  Future<WalletConnection> connect() async {
    final ethereum = _getEthereum();
    if (ethereum == null) {
      throw UnsupportedError(
        'MetaMask not detected. Install/enable the MetaMask extension and refresh the page.',
      );
    }

    final accounts = await _requestAccounts(ethereum);
    if (accounts.isEmpty) {
      throw Exception('No accounts returned by wallet.');
    }

    final chainId = await _requestChainId(ethereum);
    return WalletConnection(address: accounts.first, chainId: chainId);
  }

  @override
  void disconnect() {
  }
}

WalletAdapter createWalletAdapter() => WebWalletAdapter();
