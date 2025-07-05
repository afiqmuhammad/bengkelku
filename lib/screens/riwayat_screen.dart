// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with TickerProviderStateMixin {
  List<dynamic> transaksiMasuk = [];
  List<dynamic> transaksiKeluar = [];
  bool _loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final semuaData = await Supabase.instance.client
          .from('riwayat_transaksi')
          .select()
          .eq('user_id', userId)
          .order('tanggal', ascending: false);

      // Filter berdasarkan tipe
      setState(() {
        transaksiMasuk = semuaData.where((t) => t['tipe'] == 'masuk').toList();
        transaksiKeluar =
            semuaData.where((t) => t['tipe'] == 'keluar').toList();
        _loading = false;
      });
    } catch (e) {
      print('Error loading riwayat: $e');
      setState(() => _loading = false);
    }
  }

  Widget _buildList(List<dynamic> data, String tipe) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "Tidak ada transaksi $tipe.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isMasuk = tipe == 'masuk';
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: isMasuk ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isMasuk ? Colors.green : Colors.red,
                size: 32,
              ),
            ),
            title: Text(
              "${item['nama_barang']} (${item['kode_barang']})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item['jumlah']} x Rp${item['total'].toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey.shade300),
                      const SizedBox(width: 4),
                      Text(
                        "${item['tanggal'].toString().substring(0, 16)}",
                        style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: isMasuk ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isMasuk ? "MASUK" : "KELUAR",
                style: TextStyle(
                  color: isMasuk ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> keluarkanBarang({
    required String namaBarang,
    required String kodeBarang,
    required int jumlah,
    required double harga,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Update stok barang
    await Supabase.instance.client
        .from('barang')
        .update({'jumlah_stok': Supabase.instance.client.rpc('kurangi_stok', params: {'kode': kodeBarang, 'jumlah': jumlah})})
        .eq('kode_barang', kodeBarang);

    // Tambahkan ke riwayat_transaksi sebagai barang keluar
    await Supabase.instance.client.from('riwayat_transaksi').insert({
      'user_id': userId,
      'nama_barang': namaBarang,
      'kode_barang': kodeBarang,
      'jumlah': jumlah,
      'total': harga * jumlah,
      'tanggal': DateTime.now().toIso8601String(),
      'tipe': 'keluar',
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat Transaksi"),
          bottom: const TabBar(tabs: [Tab(text: "Masuk"), Tab(text: "Keluar")]),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(transaksiMasuk, 'masuk'),
                    _buildList(transaksiKeluar, 'keluar'),
                  ],
                ),
      ),
    );
  }
}
