// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  // ─── Controller ─────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kode = TextEditingController();
  final _jenis = TextEditingController();
  final _stok = TextEditingController();
  final _harga = TextEditingController();

  XFile? _webImage;
  File? _selectedImage;
  bool _loading = false;

  final picker = ImagePicker();
  final uuid = const Uuid();

  // ─── Utility ────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool error = false}) {
    final color = error ? Colors.red : Colors.green;
    final icon = error ? Icons.error_outline : Icons.check_circle_outline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = picked;
        } else {
          _selectedImage = File(picked.path);
        }
      });
    }
  }

  Future<String?> _uploadImage() async {
    try {
      final fileExt =
          kIsWeb
              ? _webImage!.name.split('.').last
              : _selectedImage!.path.split('.').last;
      final fileName = '${uuid.v4()}.$fileExt';
      final path = 'barang/$fileName';
      final bytes =
          kIsWeb
              ? await _webImage!.readAsBytes()
              : await _selectedImage!.readAsBytes();

      await Supabase.instance.client.storage
          .from('gambar')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );
      return Supabase.instance.client.storage.from('gambar').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload image error: $e');
      return null;
    }
  }

  // ─── Submit ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final supabase = Supabase.instance.client;
    try {
      // Cek kode barang duplikat
      final exist =
          await supabase
              .from('barang')
              .select('id')
              .eq('kode_barang', _kode.text.trim())
              .maybeSingle();
      if (exist != null) {
        throw Exception('Kode Barang sudah digunakan');
      }

      // Upload gambar jika ada
      String? imgUrl;
      final hasImg =
          (kIsWeb && _webImage != null) || (!kIsWeb && _selectedImage != null);
      if (hasImg) {
        imgUrl = await _uploadImage();
        if (imgUrl == null) throw Exception('Gagal upload gambar');
      }

      // Insert barang
      final newBarang =
          await supabase
              .from('barang')
              .insert({
                'user_id': supabase.auth.currentUser!.id,
                'nama_barang': _nama.text.trim(),
                'kode_barang': _kode.text.trim(),
                'jenis_barang': _jenis.text.trim(),
                'jumlah_stok': int.parse(_stok.text.trim()),
                'harga': double.parse(_harga.text.trim()),
                'gambar_url': imgUrl,
              })
              .select('id, jumlah_stok, harga')
              .single();

      // Catat transaksi masuk
      await supabase.from('transaksi').insert({
        'user_id': supabase.auth.currentUser!.id,
        'barang_id': newBarang['id'],
        'tipe': 'masuk',
        'jumlah': newBarang['jumlah_stok'],
        'total': newBarang['jumlah_stok'] * newBarang['harga'],
      });

      setState(() => _loading = false);
      _showSnack('Barang berhasil ditambahkan 🎉');
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  // ─── Widget builder ─────────────────────────────────────────────────────
  Widget _input(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) => TextFormField(
    controller: c,
    keyboardType: type,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D9CDB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER (gradient & back button)
              Container(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
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
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Icon(Icons.add_box, size: 64, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambah Barang',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // FORM CARD
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _input(
                          _nama,
                          'Nama Barang',
                          Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 16),
                        _input(_kode, 'Kode Barang', Icons.qr_code),
                        const SizedBox(height: 16),
                        _input(_jenis, 'Jenis Barang', Icons.category_outlined),
                        const SizedBox(height: 16),
                        _input(
                          _stok,
                          'Jumlah Stok',
                          Icons.numbers,
                          type: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _input(
                          _harga,
                          'Harga',
                          Icons.price_change,
                          type: TextInputType.number,
                        ),
                        const SizedBox(height: 20),

                        // Preview / pilih gambar
                        if (_selectedImage == null && _webImage == null)
                          const Text('Belum ada gambar')
                        else if (kIsWeb)
                          const Text('Preview gambar tidak didukung di web')
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, height: 150),
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _pickImage,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                          ),
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Gambar'),
                        ),
                        const SizedBox(height: 24),

                        // Tombol simpan
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _loading ? 'Menyimpan...' : 'Simpan',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
