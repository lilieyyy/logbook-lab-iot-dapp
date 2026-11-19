import 'package:flutter/foundation.dart' show debugPrint;
import 'package:reown_appkit/reown_appkit.dart';
import 'wallet_mobile.dart';

const String sepoliaChainId = 'eip155:11155111';

/// Sepolia dianggap aktif jika disetujui oleh sesi wallet.
bool _sesiMemilikiSepolia(ReownAppKitModal modal) {
  final session = modal.session;
  if (session == null) return false;

  final disetujui = session.getApprovedChains(namespace: 'eip155') ?? <String>[];
  debugPrint('Chain disetujui sesi: $disetujui');
  debugPrint('selectedChain: ${modal.selectedChain?.chainId}, '
      'session.chainId: ${session.chainId}');

  return disetujui.contains(sepoliaChainId);
}

Future<Object?> requestWallet(
  String method, [
  List<Object?>? params,
]) async {
  final modal = WalletMobile.appKit;
  if (modal == null) {
    throw StateError('Reown belum siap. Tekan Hubungkan MetaMask dahulu.');
  }

  final session = modal.session;
  if (session == null || !modal.isConnected) {
    throw StateError(
      'Wallet belum terhubung. Tekan Hubungkan MetaMask dan setujui koneksi.',
    );
  }

  switch (method) {
    case 'eth_chainId':
      if (!_sesiMemilikiSepolia(modal)) {
        throw StateError(
          'Sesi wallet tidak menyetujui Sepolia. '
          'Putuskan koneksi lalu hubungkan ulang.',
        );
      }
      return '0xaa36a7';

    case 'eth_requestAccounts':
      final address = session.getAddress('eip155');
      if (address == null || address.isEmpty) {
        throw StateError('Alamat wallet Ethereum tidak ditemukan.');
      }
      return <String>[address];

    case 'eth_sendTransaction':
      if (!_sesiMemilikiSepolia(modal)) {
        throw StateError('Sesi wallet tidak menyetujui Sepolia.');
      }
      if (params == null || params.isEmpty) {
        throw ArgumentError('Parameter transaksi tidak boleh kosong.');
      }

      // request() sudah membuka MetaMask sendiri untuk persetujuan.
      final result = await modal.request(
        topic: session.topic,
        chainId: sepoliaChainId,
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: params,
        ),
      );

      if (result is! String) {
        throw StateError('Wallet tidak mengembalikan hash transaksi.');
      }
      return result;

    default:
      throw UnsupportedError('Metode wallet belum didukung: $method');
  }
}