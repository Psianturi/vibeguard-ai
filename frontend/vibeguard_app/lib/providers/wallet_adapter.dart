import 'wallet_adapter_stub.dart' if (dart.library.js) 'wallet_adapter_web.dart'
    as impl;

import 'wallet_adapter_types.dart';

export 'wallet_adapter_types.dart';

WalletAdapter createWalletAdapter() => impl.createWalletAdapter();
