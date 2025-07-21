// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  void showCustomSnackbar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.blue,
    IconData icon = Icons.info,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loadBarang([String keyword = '']) async {
    setState(() => _loading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final data = await Supabase.instance.client
        .from('barang')
        .select()
        .eq('user_id', userId)
        .ilike('nama_barang', '%$keyword%')
        .order('created_at', ascending: false);

    setState(() {
      _barangList = data;
      _loading = false;
    });
  }

  void _editBarang(Map item) => _showEditBarangDialog(item);

  void _showEditBarangDialog(Map item) {
    final _namaController = TextEditingController(text: item['nama_barang']);
    final _kodeController = TextEditingController(text: item['kode_barang']);
    final _stokController = TextEditingController(
      text: item['jumlah_stok'].toString(),
    );
    final _hargaController = TextEditingController(
      text: item['harga'].toString(),
    );

    String? gambarUrl = item['gambar_url'];
    XFile? _pickedXFile;
    File? _pickedImage;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                setState(() {
                  if (kIsWeb) {
                    _pickedXFile = picked;
                    _pickedImage = null;
                  } else {
                    _pickedImage = File(picked.path);
                    _pickedXFile = null;
                  }
                });
              }
            }

            return AlertDialog(
              title: const Text("Edit Barang"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            kIsWeb
                                ? (_pickedXFile != null
                                    ? Image.network(
                                      _pickedXFile!.path,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                    : gambarUrl != null
                                    ? Image.network(
                                      gambarUrl!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                    : _emptyImage())
                                : (_pickedImage != null
                                    ? Image.file(
                                      _pickedImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                    : gambarUrl != null
                                    ? Image.network(
                                      gambarUrl!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                    : _emptyImage()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: "Nama Barang",
                      ),
                    ),
                    TextField(
                      controller: _kodeController,
                      decoration: const InputDecoration(
                        labelText: "Kode Barang",
                      ),
                    ),
                    TextField(
                      controller: _stokController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Jumlah Stok",
                      ),
                    ),
                    TextField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Harga"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nama = _namaController.text.trim();
                    final kode = _kodeController.text.trim();
                    final stok = int.tryParse(_stokController.text.trim()) ?? 0;
                    final harga =
                        int.tryParse(_hargaController.text.trim()) ?? 0;
                    String? url = gambarUrl;

                    final fileName =
                        'barang_${item['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                    try {
                      if (kIsWeb && _pickedXFile != null) {
                        final fileBytes = await _pickedXFile!.readAsBytes();
                        await Supabase.instance.client.storage
                            .from('gambar')
                            .uploadBinary(
                              fileName,
                              fileBytes,
                              fileOptions: const FileOptions(upsert: true),
                            );
                        url = Supabase.instance.client.storage
                            .from('gambar')
                            .getPublicUrl(fileName);
                      } else if (!kIsWeb && _pickedImage != null) {
                        final fileBytes = await _pickedImage!.readAsBytes();
                        await Supabase.instance.client.storage
                            .from('gambar')
                            .uploadBinary(
                              fileName,
                              fileBytes,
                              fileOptions: const FileOptions(upsert: true),
                            );
                        url = Supabase.instance.client.storage
                            .from('gambar')
                            .getPublicUrl(fileName);
                      }
                    } catch (_) {
                      showCustomSnackbar(
                        context,
                        "Gagal upload gambar",
                        backgroundColor: Colors.red,
                        icon: Icons.error,
                      );
                      return;
                    }

                    await Supabase.instance.client
                        .from('barang')
                        .update({
                          'nama_barang': nama,
                          'kode_barang': kode,
                          'jumlah_stok': stok,
                          'harga': harga,
                          'gambar_url': url,
                        })
                        .eq('id', item['id']);

                    Navigator.pop(context);
                    _loadBarang();
                    showCustomSnackbar(
                      context,
                      "Barang berhasil diperbarui",
                      backgroundColor: Colors.green,
                      icon: Icons.check_circle,
                    );
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _emptyImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.camera_alt),
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
            decoration: const InputDecoration(labelText: "Jumlah keluar"),
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
        showCustomSnackbar(
          context,
          "Stok tidak mencukupi",
          backgroundColor: Colors.red,
          icon: Icons.warning,
        );
        return;
      }

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      await supabase
          .from('barang')
          .update({'jumlah_stok': stokBaru})
          .eq('id', item['id']);
      await supabase.from('transaksi').insert({
        'barang_id': item['id'],
        'tipe': 'keluar',
        'jumlah': jumlahKeluar,
        'total': jumlahKeluar * item['harga'],
        'user_id': userId,
      });

      _loadBarang();
      showCustomSnackbar(
        context,
        "Barang berhasil dikeluarkan",
        backgroundColor: Colors.orange,
        icon: Icons.remove_shopping_cart,
      );
    }
  }

  void _hapusBarang(Map item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Hapus Barang"),
            content: Text(
              "Yakin ingin menghapus '${item['nama_barang']}' dari daftar?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      if (item['gambar_url'] != null &&
          item['gambar_url'].toString().isNotEmpty) {
        final fileName = item['gambar_url'].split('/').last;
        await Supabase.instance.client.storage.from('gambar').remove([
          fileName,
        ]);
      }

      await Supabase.instance.client
          .from('barang')
          .delete()
          .eq('id', item['id']);
      _loadBarang();
      showCustomSnackbar(
        context,
        "Barang berhasil dihapus",
        backgroundColor: Colors.red.shade400,
        icon: Icons.delete,
      );
    } catch (_) {
      showCustomSnackbar(
        context,
        "Gagal menghapus barang",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D9CDB), // biru gradasi
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30), // 👈 agar bawah melengkung
              ),
            ),

            child: Column(
              children: [
                // Tombol kembali
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Daftar Barang",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _loadBarang(val),
                    decoration: InputDecoration(
                      hintText: "Cari nama barang...",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadBarang();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
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
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  item['gambar_url'] != null
                                      ? Image.network(
                                        item['gambar_url'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.inventory),
                                      ),
                            ),
                            title: Text(
                              item['nama_barang'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Kode: ${item['kode_barang']}"),
                                Text("Stok: ${item['jumlah_stok']}"),
                                Text("Harga: Rp${item['harga']}"),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _editBarang(item);
                                if (value == 'keluar') _keluarkanBarang(item);
                                if (value == 'hapus') _hapusBarang(item);
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text("Edit"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'keluar',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_upward,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text("Keluarkan"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'hapus',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text("Hapus"),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
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
