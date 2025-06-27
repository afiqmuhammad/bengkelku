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
      return Center(child: Text("Tidak ada transaksi $tipe."));
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return ListTile(
          leading: Icon(
            tipe == 'masuk' ? Icons.arrow_downward : Icons.arrow_upward,
            color: tipe == 'masuk' ? Colors.green : Colors.red,
            size: 30,
          ),
          title: Text("${item['nama_barang']} (${item['kode_barang']})"),
          subtitle: Text(
            "${item['jumlah']} x Rp${item['total'].toStringAsFixed(0)}\n${item['tanggal'].toString().substring(0, 16)}",
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            tipe.toUpperCase(),
            style: TextStyle(
              color: tipe == 'masuk' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
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
