import 'dart:js_interop';

@JS('ethereum')
external EthereumProvider? get ethereum;

extension type EthereumProvider(JSObject _) implements JSObject {
  external JSPromise<JSAny?> request(JSObject arguments);
}

Future<Object?> requestWallet(String method, [List<Object?>? params]) async {
  final provider = ethereum;
  if (provider == null) {
    throw StateError('MetaMask tidak terdeteksi di browser ini.');
  }
  final args = <String, Object?>{
    'method': method,
    if (params != null) 'params': params,
  }.jsify() as JSObject;
  final result = await provider.request(args).toDart;
  if (method == 'eth_requestAccounts') {
    return (result as JSArray).toDart
        .map((item) => (item as JSString).toDart)
        .toList();
  }
  return (result as JSString).toDart;
}
