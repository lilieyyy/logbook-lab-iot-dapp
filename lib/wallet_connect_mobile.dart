import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'wallet_mobile.dart';

// Android menggunakan Reown AppKit.
Future<bool> openWallet(BuildContext context) async {
  await WalletMobile.connect(context);
  return true;
}

/// Pasang listener perubahan sesi; callback menerima alamat (atau null).
void Function() listenWallet(void Function(String? address) onChange) {
  void handler() {
    final modal = WalletMobile.appKit;
    onChange(modal != null && modal.isConnected
        ? modal.session?.getAddress('eip155')
        : null);
  }

  WalletMobile.appKit?.addListener(handler);
  return () => WalletMobile.appKit?.removeListener(handler);
}

/// Dipanggil saat aplikasi mulai agar sesi lama dipulihkan.
Future<void> initWallet(BuildContext context) =>
    WalletMobile.initialize(context);