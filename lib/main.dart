import 'dart:async';
import 'wallet_bridge.dart' as walletBridge;
import 'wallet_connect_launcher.dart' as walletLauncher;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart' show bytesToHex;
import 'config.dart';
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Logbook Lab IoT DApp',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LogbookHomePage(),
      );
}
class LogbookHomePage extends StatefulWidget {
  const LogbookHomePage({super.key});
  @override
  State<LogbookHomePage> createState() => _LogbookHomePageState();
}
class _LogbookHomePageState extends State<LogbookHomePage> {
  late final http.Client httpClient;
  late final Web3Client ethClient;
  List<Map<String, dynamic>> daftarLog = [];
  final Set<int> dipilih = {};
  bool isLoading = true;
  bool isSending = false;
  String? wallet;
    String? errorMuat;
  void Function()? _lepasListenerWallet;
  @override
  void initState() {
    super.initState();
    httpClient = http.Client();
    ethClient = Web3Client(Config.rpcUrl, httpClient);
    muatLogDariBlockchain();
    WidgetsBinding.instance.addPostFrameCallback((_) => _siapkanWallet());
  }
  // Android: inisialisasi Reown, pulihkan sesi, dan pantau perubahan alamat.
  Future<void> _siapkanWallet() async {
    try {
      await walletLauncher.initWallet(context);
      _lepasListenerWallet?.call();
      _lepasListenerWallet = walletLauncher.listenWallet((address) {
        if (mounted) setState(() => wallet = address);
      });
    } catch (e) {
      debugPrint('Init wallet gagal: $e');
    }
  }
  @override
  void dispose() {
    _lepasListenerWallet?.call();
    ethClient.dispose();
    httpClient.close();
    super.dispose();
  }
  void pesan(String value, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(value),
        backgroundColor: error ? Colors.red : null,
      ));
  }
  DeployedContract buatContract() => DeployedContract(
        ContractAbi.fromJson(Config.contractAbi, 'LogbookLabIoT'),
        EthereumAddress.fromHex(Config.contractAddress.trim()),
      );
  Future<Object?> requestWallet(String method, [List<Object?>? params]) =>
      walletBridge.requestWallet(method, params);
  Future<void> pastikanSepolia() async {
    final chain = await requestWallet('eth_chainId') as String;
    if (chain.toLowerCase() != '0xaa36a7') {
      throw StateError('Pilih jaringan Sepolia (chain ID 11155111) di MetaMask.');
    }
  }
  Future<String> hubungkanWallet() async {
    await pastikanSepolia();
    final result = await requestWallet('eth_requestAccounts');
    final accounts = result as List<String>;
    if (accounts.isEmpty) throw StateError('Tidak ada akun MetaMask yang dipilih.');
    final address = accounts.first;
    if (!mounted) throw StateError('Halaman sudah ditutup.');
    setState(() => wallet = address);
    return address;
  }
  Future<void> muatLogDariBlockchain() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMuat = null;
    });
    try {
      final contract = buatContract();
      debugPrint('Alamat kontrak: ${contract.address.hex}');
      final chainId = await ethClient.getChainId();
      debugPrint('RPC chain ID: $chainId');
      if (chainId != BigInt.from(11155111)) {
        throw StateError('RPC bukan jaringan Sepolia: $chainId');
      }
      final code = await ethClient.getCode(contract.address);
      if (code.isEmpty) throw StateError('Alamat kontrak tidak memiliki bytecode.');
      // Semua panggilan menggunakan blok yang sama.
      final block = await ethClient.getBlockNumber();
      final atBlock = BlockNum.exact(block);
      final count = await ethClient.call(
        contract: contract,
        function: contract.function('jumlahLog'),
        params: [],
        atBlock: atBlock,
      );
      final total = (count.first as BigInt).toInt();
      debugPrint('Blok: $block, jumlahLog: $total');
      final logs = <Map<String, dynamic>>[];
      for (var i = 0; i < total; i++) {
        debugPrint('Membaca ambilLog($i)');
        try {
          final data = await ethClient.call(
            contract: contract,
            function: contract.function('ambilLog'),
            params: [BigInt.from(i)],
            atBlock: atBlock,
          );
          logs.add({
            'id': i,
            'namaAlat': data[0] as String,
            'namaPeminjam': data[1] as String,
            'sudahKembali': data[2] as bool,
            'waktuPinjam': DateTime.fromMillisecondsSinceEpoch(
              (data[3] as BigInt).toInt() * 1000,
            ),
          });
        } catch (e) {
          throw StateError('ambilLog($i) gagal pada blok $block '
              '(jumlahLog=$total, kontrak=${contract.address.hex}): $e');
        }
      }
      if (!mounted) return;
      setState(() {
        daftarLog = logs;
        dipilih.removeWhere(
          (id) => id >= logs.length || logs[id]['sudahKembali'] == true,
        );
      });
    } catch (e, st) {
      debugPrint('Gagal membaca blockchain: $e\n$st');
      if (mounted) setState(() => errorMuat = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> kirimTransaksi(String namaFungsi, List<dynamic> parameters) async {
    await pastikanSepolia();
    final from = await hubungkanWallet();
    final contract = buatContract();
    final code = await ethClient.getCode(contract.address);
    if (code.isEmpty) throw StateError('Alamat kontrak tidak memiliki kode di Sepolia.');
    final encoded = contract.function(namaFungsi).encodeCall(parameters);
    final data = bytesToHex(encoded, include0x: true);
    final result = await requestWallet('eth_sendTransaction', [
      {
        'from': from,
        'to': contract.address.hex,
        'data': data,
        'value': '0x0',
      }
    ]);
    final hash = result as String;
    debugPrint('Transaksi dikirim: $hash');
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final receipt = await ethClient.getTransactionReceipt(hash);
      if (receipt == null) continue;
      if (receipt.status != true) {
        throw StateError('Transaksi gagal (reverted). Periksa: https://sepolia.etherscan.io/tx/$hash');
      }
      pesan('Transaksi berhasil dikonfirmasi!');
      return;
    }
    throw TimeoutException('Transaksi belum terkonfirmasi. Periksa: https://sepolia.etherscan.io/tx/$hash');
  }
  Future<void> proses(Future<void> Function() action) async {
    if (isSending) return;
    setState(() => isSending = true);
    try {
      await action();
    } catch (e, st) {
      debugPrint('ERROR TRANSAKSI: $e\n$st');
            final ditolak = RegExp(r'denied|rejected|cancel', caseSensitive: false)
          .hasMatch(e.toString());
      pesan(
        ditolak ? 'Transaksi dibatalkan di MetaMask.' : 'Gagal: $e',
        error: !ditolak,
      );
    } finally {
      await muatLogDariBlockchain();
      if (mounted) setState(() => isSending = false);
    }
  }
  Future<void> tambah(String alat, String peminjam) => proses(() =>
      kirimTransaksi('tambahPeminjaman', [alat.trim(), peminjam.trim()]));
  Future<void> hapus(int id) => proses(() async {
        await kirimTransaksi('hapusLog', [BigInt.from(id)]);
        dipilih.clear();
      });
  Future<void> tandaiKembali() => proses(() async {
        final ids = dipilih.toList()..sort();
        for (final id in ids) {
          await kirimTransaksi('tandaiKembali', [BigInt.from(id)]);
        }
        dipilih.clear();
      });
  void toggle(int id) => setState(() {
        if (!dipilih.add(id)) dipilih.remove(id);
      });
  void dialogTambah() {
    final alat = TextEditingController();
    final peminjam = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catat Peminjaman Alat'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: alat,
            decoration: const InputDecoration(hintText: 'Nama Alat (ESP32 / Sensor)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: peminjam,
            decoration: const InputDecoration(hintText: 'Nama Peminjam / Kelompok'),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (alat.text.trim().isEmpty || peminjam.text.trim().isEmpty) {
                pesan('Nama alat dan peminjam wajib diisi.', error: true);
                return;
              }
              final a = alat.text;
              final p = peminjam.text;
              Navigator.pop(dialogContext);
              tambah(a, p);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Logbook Lab IoT (Sepolia)'),
          actions: [
            TextButton.icon(
              onPressed: isSending ? null : () async {
                try {
                  final isMobile = await walletLauncher.openWallet(context);
                  if (isMobile) {
                    // Reown membuka modal. Belum berarti wallet sudah terhubung.
                    return;
                  }
                  // Pada Flutter Web, gunakan koneksi ekstensi MetaMask lama.
                  await hubungkanWallet();
                  pesan('MetaMask terhubung.');
                } catch (e) {
                  pesan('Gagal menghubungkan MetaMask: $e', error: true);
                }
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(wallet == null
                  ? 'Hubungkan MetaMask'
                  : '${wallet!.substring(0, 6)}...${wallet!.substring(wallet!.length - 4)}'),
            ),
            IconButton(
              onPressed: isSending ? null : muatLogDariBlockchain,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: isLoading || isSending
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(isSending ? 'Menunggu konfirmasi MetaMask / Sepolia...' : 'Memuat log...'),
                ]),
              )
            : errorMuat != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const Text('Gagal membaca data blockchain.'),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(errorMuat!, textAlign: TextAlign.center),
                      ),
                      ElevatedButton(
                        onPressed: muatLogDariBlockchain,
                        child: const Text('Coba Lagi'),
                      ),
                    ]),
                  )
                : daftarLog.isEmpty
                    ? const Center(child: Text('Belum ada data peminjaman di blockchain.'))
                    : ListView.builder(
                        itemCount: daftarLog.length,
                        itemBuilder: (context, index) {
                          final log = daftarLog[index];
                          final id = log['id'] as int;
                          final kembali = log['sudahKembali'] as bool;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: kembali ? null : () => toggle(id),
                              leading: Checkbox(
                                value: kembali || dipilih.contains(id),
                                onChanged: kembali ? null : (_) => toggle(id),
                              ),
                              title: Text(
                                'Alat: ${log['namaAlat']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: kembali ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                'Peminjam: ${log['namaPeminjam']}\n'
                                'ID: $id • ${(log['waktuPinjam'] as DateTime).toLocal().toString().split('.')[0]}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: isSending ? null : () => hapus(id),
                              ),
                            ),
                          );
                        },
                      ),
        bottomNavigationBar: dipilih.isEmpty || isSending || isLoading
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: tandaiKembali,
                    icon: const Icon(Icons.assignment_returned),
                    label: Text('Tandai ${dipilih.length} Alat Dikembalikan'),
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: isSending ? null : dialogTambah,
          child: const Icon(Icons.add),
        ),
      );
}
