import 'package:flutter/material.dart';

// Flutter Web tetap menggunakan MetaMask browser.
Future<bool> openWallet(BuildContext context) async {
  return false;
}

void Function() listenWallet(void Function(String? address) onChange) => () {};

Future<void> initWallet(BuildContext context) async {}