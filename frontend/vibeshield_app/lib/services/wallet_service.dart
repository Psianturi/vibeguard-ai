import 'package:flutter/foundation.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config.dart';

class WalletService {
  static WalletService? _instance;
  Web3App? _web3App;
  SessionData? _session;
  String? _currentAddress;
  String? _lastError;

  WalletService._();

  static WalletService get instance {
    _instance ??= WalletService._();
    return _instance!;
  }

  bool get isConnected => _session != null && _currentAddress != null;
  String? get address => _currentAddress;
  String? get lastError => _lastError;

  Future<void> init() async {
    if (_web3App != null) return;

    try {
      _lastError = null;
      final projectId = AppConfig.walletConnectProjectId.trim();
      if (projectId.isEmpty) {
        throw Exception('WalletConnect Project ID is not configured');
      }

      _web3App = await Web3App.createInstance(
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'VibeShield AI',
          description: 'Crypto Portfolio Guardian',
          url: 'https://vibeshield.ai',
          icons: ['https://vibeshield.ai/icon.png'],
        ),
      );

      // Listen to session events
      _web3App!.onSessionConnect.subscribe(_onSessionConnect);
      _web3App!.onSessionDelete.subscribe(_onSessionDelete);
    } catch (e) {
      _lastError = e.toString();
      debugPrint('WalletConnect init error: $e');
    }
  }

  Future<String?> connect() async {
    try {
      _lastError = null;
      await init();

      if (_web3App == null) {
        throw Exception('WalletConnect not initialized');
      }

      // Check if already connected
      if (_session != null) {
        return _currentAddress;
      }

      // Create connection
      final ConnectResponse response = await _web3App!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:56'], // BSC Mainnet
            methods: ['eth_sendTransaction', 'personal_sign'],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final Uri? uri = response.uri;
      if (uri != null) {
        // Open wallet app
        if (kIsWeb) {
          // For web, show QR code or deep link
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // For mobile, try known wallet deep links first, then fallback to the raw WalletConnect URI.
          final encoded = Uri.encodeComponent(uri.toString());
          final candidates = <Uri>[
            Uri.parse('metamask://wc?uri=$encoded'),
            Uri.parse('trust://wc?uri=$encoded'),
            uri,
          ];

          bool launched = false;
          for (final candidate in candidates) {
            try {
              final ok = await launchUrl(candidate, mode: LaunchMode.externalApplication);
              if (ok) {
                launched = true;
                break;
              }
            } catch (_) {
            }
          }

          if (!launched) {
            throw Exception('No compatible wallet app found. Install MetaMask/Trust Wallet and try again.');
          }
        }
      }

      // Wait for session approval
      _session = await response.session.future.timeout(const Duration(minutes: 1));
      
      if (_session != null) {
        final accounts = _session!.namespaces['eip155']?.accounts ?? [];
        if (accounts.isNotEmpty) {
          _currentAddress = accounts.first.split(':').last;
          return _currentAddress;
        }
      }

      return null;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('WalletConnect error: $e');
      return null;
    }
  }

  Future<void> disconnect() async {
    if (_session != null && _web3App != null) {
      try {
        await _web3App!.disconnectSession(
          topic: _session!.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
        );
      } catch (e) {
        debugPrint('Disconnect error: $e');
      }
    }
    _session = null;
    _currentAddress = null;
    _lastError = null;
  }

  void _onSessionConnect(SessionConnect? event) {
    if (event != null) {
      _session = event.session;
      final accounts = _session!.namespaces['eip155']?.accounts ?? [];
      if (accounts.isNotEmpty) {
        _currentAddress = accounts.first.split(':').last;
      }
    }
  }

  void _onSessionDelete(SessionDelete? event) {
    _session = null;
    _currentAddress = null;
  }

  Future<String?> signMessage(String message) async {
    if (_session == null || _web3App == null || _currentAddress == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final signature = await _web3App!.request(
        topic: _session!.topic,
        chainId: 'eip155:56',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [message, _currentAddress],
        ),
      );

      return signature as String?;
    } catch (e) {
      debugPrint('Sign message error: $e');
      return null;
    }
  }

  void dispose() {
    _web3App?.onSessionConnect.unsubscribe(_onSessionConnect);
    _web3App?.onSessionDelete.unsubscribe(_onSessionDelete);
  }
}
