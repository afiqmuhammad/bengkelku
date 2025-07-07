// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
    final data = await Supabase.instance.client
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

  void _editBarang(Map item) {
    _showEditBarangDialog(item);
  }

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
    XFile? _pickedXFile; // Web
    File? _pickedImage; // Mobile

    _showEditBarangDialog(item);
  }

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
    XFile? _pickedXFile; // Web
    File? _pickedImage; // Mobile

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
                                    gambarUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                    ),
                                  ))
                              : (_pickedImage != null
                                  ? Image.file(
                                    _pickedImage!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : gambarUrl != null
                                  ? Image.network(
                                    gambarUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                    ),
                                  )),
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
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal upload gambar")),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Barang berhasil diupdate")),
                    );
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
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
                                    gambarUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                    ),
                                  ))
                              : (_pickedImage != null
                                  ? Image.file(
                                    _pickedImage!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : gambarUrl != null
                                  ? Image.network(
                                    gambarUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                    ),
                                  )),
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
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal upload gambar")),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Barang berhasil diupdate")),
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

<<<<<<< HEAD
      // Simpan riwayat pengeluaran
<<<<<<< HEAD
<<<<<<< HEAD
=======
      await Supabase.instance.client.from('riwayat').insert({
>>>>>>> 3bd429191305de526c40668f7f1246516b0fc3b4
      await Supabase.instance.client.from('transaksi').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
=======
      await Supabase.instance.client.from('riwayat').insert({
>>>>>>> origin/andri_fitur-edit
<<<<<<< HEAD
=======
      await Supabase.instance.client.from('riwayat').insert({
>>>>>>> origin/Zulfa_Menyesuaikan
=======
>>>>>>> 42f7a105dc18dba8da40f3891c2111fbc8dfe1d7
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                : Expanded(
                  child:
                      _barangList.isEmpty
                          ? const Center(child: Text("Belum ada barang."))
                          : ListView.builder(
                            itemCount: _barangList.length,
                            itemBuilder: (context, index) {
                              final item = _barangList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading:
                                      item['gambar_url'] != null
                                          ? Image.network(
                                            item['gambar_url'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                          : const Icon(
                                            Icons.inventory,
                                            size: 40,
                                          ),
                                  title: Text(item['nama_barang']),
                                  subtitle: Text(
                                    "Kode: ${item['kode_barang']} • Stok: ${item['jumlah_stok']} • Harga: Rp${item['harga']}",
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'edit') _editBarang(item);
                                      if (val == 'keluar')
                                        _keluarkanBarang(item);
                                    },
                                    itemBuilder:
                                        (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text("Edit"),
                                          ),
                                          PopupMenuItem(
                                            value: 'keluar',
                                            child: Text("Keluarkan"),
                                          ),
                                        ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
          ],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                : Expanded(
                  child:
                      _barangList.isEmpty
                          ? const Center(child: Text("Belum ada barang."))
                          : ListView.builder(
                            itemCount: _barangList.length,
                            itemBuilder: (context, index) {
                              final item = _barangList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading:
                                      item['gambar_url'] != null
                                          ? Image.network(
                                            item['gambar_url'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                          : const Icon(
                                            Icons.inventory,
                                            size: 40,
                                          ),
                                  title: Text(item['nama_barang']),
                                  subtitle: Text(
                                    "Kode: ${item['kode_barang']} • Stok: ${item['jumlah_stok']} • Harga: Rp${item['harga']}",
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'edit') _editBarang(item);
                                      if (val == 'keluar')
                                        _keluarkanBarang(item);
                                    },
                                    itemBuilder:
                                        (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text("Edit"),
                                          ),
                                          PopupMenuItem(
                                            value: 'keluar',
                                            child: Text("Keluarkan"),
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
      ),
    );
  }
}
