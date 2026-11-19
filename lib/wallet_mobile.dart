import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Koneksi wallet Android lewat Reown AppKit (WalletConnect v2).
class WalletMobile {
  static ReownAppKitModal? appKit;

  /// ID MetaMask di katalog WalletConnect Explorer.
  static const String metamaskWalletId =
      'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96';

  static const String sepoliaChainIdNumeric = '11155111';

  static const String projectId = String.fromEnvironment(
    'REOWN_PROJECT_ID',
    defaultValue: 'c205532fdadd726f63dd80e33043b52c',
  );

  static Future<void> initialize(BuildContext context) async {
    if (appKit != null) return;

    // Daftarkan Sepolia (testnet) sebagai jaringan yang didukung modal.
    const sepolia = ReownAppKitModalNetworkInfo(
      name: 'Sepolia',
      chainId: '11155111',
      currency: 'ETH',
      rpcUrl: 'https://ethereum-sepolia-rpc.publicnode.com',
      explorerUrl: 'https://sepolia.etherscan.io',
      isTestNetwork: true,
    );
    ReownAppKitModalNetworks.addSupportedNetworks('eip155', [sepolia]);

    final modal = ReownAppKitModal(
      context: context,
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'Logbook Lab IoT',
        description: 'Aplikasi peminjaman alat berbasis Sepolia',
        url: 'https://example.com',
        icons: ['https://example.com/favicon.ico'],
        redirect: Redirect(native: 'chaintodoapp://'),
      ),
      featuredWalletIds: {metamaskWalletId},
      includedWalletIds: {metamaskWalletId},
    );

    await modal.init(); // memulihkan sesi tersimpan jika ada
    appKit = modal;
  }

  static Future<void> connect(BuildContext context) async {
    if (appKit == null) await initialize(context);
    final modal = appKit;
    if (modal == null) {
      throw StateError('Reown AppKit belum diinisialisasi.');
    }
    if (modal.isConnected) return;
    await modal.openModalView();
  }

  static Future<void> disconnect() async => appKit?.disconnect();
}