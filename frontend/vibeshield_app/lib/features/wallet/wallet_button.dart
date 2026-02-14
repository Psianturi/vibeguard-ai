import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/wallet_provider.dart';

class WalletButton extends ConsumerWidget {
  const WalletButton({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);

    if (walletState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (walletState.isConnected) {
      return PopupMenuButton(
        child: compact
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.account_balance_wallet),
              )
            : Chip(
                avatar: const Icon(Icons.account_balance_wallet, size: 16),
                label: Text(walletState.shortAddress),
                backgroundColor: Colors.green.withOpacity(0.2),
              ),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Address'),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () {
              if (walletState.address != null) {
                Clipboard.setData(ClipboardData(text: walletState.address!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied!')),
                );
              }
            },
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Disconnect', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () {
              ref.read(walletProvider.notifier).disconnect();
            },
          ),
        ],
      );
    }

    if (compact) {
      return IconButton(
        tooltip: 'Connect Wallet',
        onPressed: () async {
          await ref.read(walletProvider.notifier).connect();
          final err = ref.read(walletProvider).error;
          if (err != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.account_balance_wallet),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        await ref.read(walletProvider.notifier).connect();

        final err = ref.read(walletProvider).error;
        if (err != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.account_balance_wallet, size: 18),
      label: const Text('Connect Wallet'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
