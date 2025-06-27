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
      await Supabase.instance.client.from('riwayat').insert({
        'barang_id': item['id'],
        'tipe': 'keluar',
        'jumlah': jumlahKeluar,
        'harga': item['harga'],
        'user_id': Supabase.instance.client.auth.currentUser!.id,
      });

      _loadBarang();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Barang")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _loadBarang(val),
              decoration: InputDecoration(
                hintText: "Cari nama barang...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _barangList.length,
                      itemBuilder: (context, index) {
                        final item = _barangList[index];
                        return ListTile(
                          leading:
                              item['gambar_url'] != null
                                  ? Image.network(
                                    item['gambar_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                  : const Icon(Icons.inventory),
                          title: Text(item['nama_barang']),
                          subtitle: Text(
                            "Kode: ${item['kode_barang']} • Stok: ${item['jumlah_stok']} • Harga: Rp${item['harga']}",
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
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
