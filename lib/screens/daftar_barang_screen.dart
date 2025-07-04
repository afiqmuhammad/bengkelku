// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DaftarBarangScreen extends StatefulWidget {
  const DaftarBarangScreen({super.key});

  @override
  State<DaftarBarangScreen> createState() => _DaftarBarangScreenState();
}

class _DaftarBarangScreenState extends State<DaftarBarangScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _barangList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  Future<void> _loadBarang([String keyword = '']) async {
    setState(() => _loading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final query = Supabase.instance.client
        .from('barang')
        .select()
        .eq('user_id', userId)
        .ilike('nama_barang', '%$keyword%')
        .order('created_at', ascending: false);

    final data = await query;
    setState(() {
      _barangList = data;
      _loading = false;
    });
  }

  void _editBarang(Map item) {
    // bisa nanti diarahkan ke halaman edit
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit belum dibuat"),
          content: const Text("Nanti kita buat fitur edit."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _keluarkanBarang(Map item) async {
    final jumlahKeluar = await showDialog<int>(
      context: context,
      builder: (_) {
        final _jumlah = TextEditingController();
        return AlertDialog(
          title: const Text("Pengeluaran Barang"),
          content: TextField(
            controller: _jumlah,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Jumlah yang keluar"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                final jumlah = int.tryParse(_jumlah.text.trim());
                Navigator.pop(context, jumlah);
              },
              child: const Text("Keluarkan"),
            ),
          ],
        );
      },
    );

    if (jumlahKeluar != null && jumlahKeluar > 0) {
      final stokBaru = item['jumlah_stok'] - jumlahKeluar;
      if (stokBaru < 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Stok tidak mencukupi")));
        return;
      }

      await Supabase.instance.client
          .from('barang')
          .update({'jumlah_stok': stokBaru})
          .eq('id', item['id']);

      // Simpan riwayat pengeluaran
      await Supabase.instance.client.from('transaksi').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'barang_id': item['id'],
        'tipe': 'keluar',
        'jumlah': jumlahKeluar,
        'total': jumlahKeluar * item['harga'],
      });

      _loadBarang();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Daftar Barang"),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => _loadBarang(val),
                    decoration: InputDecoration(
                      hintText: "Cari nama barang...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _barangList.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          "Belum ada barang.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _barangList.length,
                        itemBuilder: (context, index) {
                          final item = _barangList[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading:
                                  item['gambar_url'] != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item['gambar_url'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        child: Icon(
                                          Icons.inventory,
                                          color: Colors.blue.shade700,
                                        ),
                                        radius: 25,
                                      ),
                              title: Text(
                                item['nama_barang'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Kode: ${item['kode_barang']} • Stok: ${item['jumlah_stok']} • Harga: Rp${item['harga']}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') _editBarang(item);
                                  if (val == 'keluar') _keluarkanBarang(item);
                                },
                                itemBuilder:
                                    (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Edit"),
                                      ),
                                      const PopupMenuItem(
                                        value: 'keluar',
                                        child: Text("Keluarkan"),
                                      ),
                                    ],
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
