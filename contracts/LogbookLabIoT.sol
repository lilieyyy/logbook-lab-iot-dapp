// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LogbookLabIoT {
    struct Peminjaman {
        string namaAlat;
        string namaPeminjam;
        bool sudahKembali;
        uint256 waktuPinjam;
        address pembuat;
    }

    Peminjaman[] private daftarPeminjaman;

    event PinjamBaru(uint256 id, string namaAlat, string namaPeminjam);
    event AlatDikembalikan(uint256 id);
    event LogDihapus(uint256 id);

    function tambahPeminjaman(string calldata _namaAlat, string calldata _namaPeminjam) external {
        require(bytes(_namaAlat).length > 0, "Nama alat tidak boleh kosong");
        require(bytes(_namaPeminjam).length > 0, "Nama peminjam tidak boleh kosong");

        daftarPeminjaman.push(
            Peminjaman(_namaAlat, _namaPeminjam, false, block.timestamp, msg.sender)
        );

        emit PinjamBaru(daftarPeminjaman.length - 1, _namaAlat, _namaPeminjam);
    }

    function tandaiKembali(uint256 id) external {
        require(id < daftarPeminjaman.length, "Data tidak ada");
        require(daftarPeminjaman[id].pembuat == msg.sender, "Bukan pembuat log ini");

        daftarPeminjaman[id].sudahKembali = true;
        emit AlatDikembalikan(id);
    }

    function hapusLog(uint256 id) external {
        require(id < daftarPeminjaman.length, "Data tidak ada");
        require(daftarPeminjaman[id].pembuat == msg.sender, "Bukan pembuat log ini");

        for (uint256 i = id; i < daftarPeminjaman.length - 1; i++) {
            daftarPeminjaman[i] = daftarPeminjaman[i + 1];
        }
        daftarPeminjaman.pop();

        emit LogDihapus(id);
    }

    function jumlahLog() external view returns (uint256) {
        return daftarPeminjaman.length;
    }

    function ambilLog(uint256 id)
        external
        view
        returns (string memory, string memory, bool, uint256, address)
    {
        require(id < daftarPeminjaman.length, "Data tidak ada");

        Peminjaman memory p = daftarPeminjaman[id];
        return (p.namaAlat, p.namaPeminjam, p.sudahKembali, p.waktuPinjam, p.pembuat);
    }
}