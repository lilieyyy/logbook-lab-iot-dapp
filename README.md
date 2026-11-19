# Logbook Lab IoT — Flutter & Ethereum Sepolia

Aplikasi logbook peminjaman alat laboratorium IoT berbasis **Flutter Web** yang terhubung ke smart contract Solidity di blockchain **Ethereum Sepolia Testnet**. Data peminjaman dibaca dari blockchain, sedangkan transaksi penambahan, pengembalian, dan penghapusan dikonfirmasi melalui **MetaMask**.

Proyek ini dibuat untuk tugas mata kuliah **Pemrograman Mobile 2**.

## Fitur

- Menghubungkan wallet MetaMask pada jaringan Sepolia.
- Menampilkan daftar peminjaman alat dari smart contract.
- Menambahkan peminjaman baru (nama alat dan nama peminjam).
- Menandai alat sudah dikembalikan.
- Menghapus log peminjaman (hanya oleh pembuat log).
- Menyegarkan daftar dan menampilkan status atau pesan kesalahan transaksi.

> **Catatan:** Penghapusan log pada kontrak menggunakan penggeseran indeks array. Karena itu ID log dapat berubah setelah penghapusan.

## Teknologi

- **Flutter / Dart** — antarmuka aplikasi web.
- **Solidity ^0.8.20** — smart contract `LogbookLabIoT`.
- **Ethereum Sepolia Testnet** — jaringan pengujian.
- **MetaMask** — koneksi wallet dan penandatanganan transaksi.
- **web3dart** dan **http** — pembacaan smart contract melalui RPC.
- **Remix IDE** — kompilasi dan deployment smart contract.

Versi Flutter dan versi paket yang tepat dapat dilihat dengan `flutter --version` dan pada `pubspec.lock` di repositori.

## Informasi smart contract

| Komponen | Nilai |
| --- | --- |
| Nama kontrak | `LogbookLabIoT` |
| Jaringan | Ethereum Sepolia Testnet |
| Chain ID | `11155111` |
| Alamat kontrak | `0xbD984854a14D65264b6bd4FcFD69dF96a195A0f0` |
| RPC publik | `https://ethereum-sepolia-rpc.publicnode.com` |
| Explorer | [Lihat kontrak di Sepolia Etherscan](https://sepolia.etherscan.io/address/0xbD984854a14D65264b6bd4FcFD69dF96a195A0f0) |

Fungsi utama smart contract:

| Fungsi | Kegunaan |
| --- | --- |
| `jumlahLog()` | Membaca jumlah log peminjaman |
| `ambilLog(uint256 id)` | Membaca detail peminjaman berdasarkan ID |
| `tambahPeminjaman(string, string)` | Menambahkan peminjaman baru |
| `tandaiKembali(uint256 id)` | Menandai alat sudah dikembalikan |
| `hapusLog(uint256 id)` | Menghapus log oleh pembuatnya |

Setiap log menyimpan nama alat, nama peminjam, status pengembalian, waktu pinjam, dan alamat wallet pembuat. Kontrak saat ini **tidak menyimpan waktu kembali secara terpisah**.

## Persiapan

1. Instal **Flutter SDK** dan **VS Code** atau editor lain.
2. Instal **Google Chrome** dan ekstensi **MetaMask** pada profil Chrome yang sama.
3. Siapkan akun MetaMask khusus testnet dan pilih jaringan **Sepolia**.
4. Siapkan sedikit **Sepolia ETH** dari faucet untuk biaya transaksi pengujian.
5. Pastikan konfigurasi `lib/config.dart` menunjuk ke RPC dan alamat kontrak di atas serta memuat ABI yang sesuai.

## Cara menjalankan

Buka terminal pada folder utama proyek (folder yang berisi `pubspec.yaml`), kemudian jalankan:

```bash
flutter pub get
flutter run -d web-server --web-port=8080
```

Buka **http://localhost:8080** pada Chrome utama yang sudah terpasang MetaMask. Jika port 8080 sedang dipakai, pilih port lain dan buka URL yang ditampilkan di terminal.

> Jalankan aplikasi pada browser dengan ekstensi MetaMask aktif. `flutter run -d chrome` dapat membuka profil Chrome sementara yang tidak memiliki ekstensi tersebut.

## Cara menggunakan

1. Buka aplikasi dan hubungkan akun MetaMask jika diminta.
2. Pastikan jaringan wallet adalah **Sepolia**.
3. Tekan tombol **+**, isi nama alat dan nama peminjam, lalu simpan.
4. Setujui transaksi melalui MetaMask.
5. Tunggu transaksi berhasil dikonfirmasi, lalu gunakan tombol **Refresh** untuk memuat data terbaru.
6. Untuk mengembalikan atau menghapus peminjaman, gunakan tindakan yang tersedia pada log terkait. Konfirmasi transaksi kembali melalui MetaMask.

### Memeriksa transaksi

Buka aktivitas transaksi di MetaMask atau lihat transaksi pada [Sepolia Etherscan](https://sepolia.etherscan.io/). Pastikan **Status: Success** dan alamat tujuan sesuai alamat smart contract di atas. Transaksi berhasil tidak selalu berarti tampilan sudah diperbarui; gunakan Refresh bila perlu.

## Struktur proyek (berkas utama)

```text
lib/
  main.dart       # Antarmuka, pembacaan log, dan interaksi MetaMask
  config.dart     # RPC Sepolia, alamat kontrak, dan ABI
pubspec.yaml      # Dependensi Flutter
README.md         # Dokumentasi proyek
```

Sertakan juga berkas sumber **`.sol`** smart contract dalam repositori untuk memenuhi kebutuhan dokumentasi tugas. Lokasi berkas Solidity mengikuti struktur repositori masing-masing.

## Keamanan

- **Jangan pernah menyimpan private key atau seed phrase** di `main.dart`, `config.dart`, README, maupun GitHub.
- Transaksi Flutter Web menggunakan MetaMask agar penandatanganan dilakukan oleh wallet, bukan dengan menanam private key ke aplikasi.
- Jangan mengandalkan `--dart-define` untuk menyembunyikan private key dalam aplikasi web yang didistribusikan.
- Gunakan wallet khusus **Sepolia Testnet**, bukan wallet utama yang menyimpan aset sungguhan.
- Data yang dicatat di blockchain bersifat publik. Gunakan nama samaran/kode pengujian, bukan data pribadi sensitif.
- Jika private key pernah terunggah atau dibagikan, anggap sudah bocor dan gunakan wallet baru.

## Batasan dan pengembangan

Implementasi MetaMask pada kode Flutter ini ditujukan untuk **Flutter Web**. Dukungan Android/APK memerlukan integrasi wallet khusus perangkat seluler dan pengujian tambahan; versi web tidak otomatis menjadi aplikasi Android yang dapat menandatangani transaksi. Fitur lanjutan yang memungkinkan antara lain filter log, pembaruan otomatis dari event smart contract, dan pencatatan waktu kembali.

## Pengujian

Skenario pengujian yang disarankan:

1. `jumlahLog()` di Remix mengembalikan jumlah data yang sesuai.
2. `ambilLog(0)` mengembalikan detail log pertama bila jumlah log lebih dari nol.
3. Menambahkan peminjaman melalui Flutter menghasilkan transaksi **Success** di Etherscan.
4. Data baru terlihat setelah aplikasi disegarkan.
5. Aksi pengembalian dan penghapusan hanya dapat dilakukan oleh wallet pembuat log.

## Referensi

- [Flutter](https://docs.flutter.dev/)
- [Solidity](https://docs.soliditylang.org/)
- [Remix IDE](https://remix.ethereum.org/)
- [MetaMask](https://metamask.io/)
- [Sepolia Etherscan](https://sepolia.etherscan.io/)

Dokumentasi ini disusun untuk proyek pembelajaran Flutter dan blockchain Sepolia. Jika kode diadaptasi dari tutorial atau sumber lain, cantumkan atribusi yang sesuai di bagian ini.
