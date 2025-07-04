// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Halaman untuk menambahkan barang baru sekaligus mencatat transaksi "masuk".
class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  // ──────────────────────────────────────────────────────────────────────────
  // Controller & util
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kode = TextEditingController();
  final _jenis = TextEditingController();
  final _stok = TextEditingController();
  final _harga = TextEditingController();

  XFile? _webImage; // image untuk web
  File? _selectedImage; // image untuk mobile
  bool _loading = false;

  final picker = ImagePicker();
  final uuid = const Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // Gambar
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _selectedImage = File(pickedFile.path);
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

      final res = await Supabase.instance.client.storage
          .from('gambar')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      if (res.isEmpty) return null;
      return Supabase.instance.client.storage.from('gambar').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload image error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Submit form
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final supabase = Supabase.instance.client;
    try {
      // 1️⃣ Cek kode barang duplikat
      final existing =
          await supabase
              .from('barang')
              .select('id')
              .eq('kode_barang', _kode.text.trim())
              .maybeSingle();
      if (existing != null) {
        throw Exception(
          'Kode Barang sudah digunakan, silakan pilih kode lain.',
        );
      }

      // 2️⃣ Upload gambar (jika ada)
      String? imageUrl;
      final hasImage =
          (kIsWeb && _webImage != null) || (!kIsWeb && _selectedImage != null);
      if (hasImage) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) throw Exception('Gagal upload gambar');
      }

      // 3️⃣ Insert ke tabel barang & langsung ambil hasil barunya
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
                'gambar_url': imageUrl,
              })
              .select('id, jumlah_stok, harga')
              .single();

      // 4️⃣ Catat transaksi "masuk"
      await supabase.from('transaksi').insert({
        'user_id': supabase.auth.currentUser!.id,
        'barang_id': newBarang['id'],
        'tipe': 'masuk',
        'jumlah': newBarang['jumlah_stok'],
        'total': newBarang['jumlah_stok'] * newBarang['harga'],
      });

      // ────────────────────
      setState(() => _loading = false);
      Navigator.pop(
        context,
        true,
      ); // true → agar halaman sebelumnya bisa refresh
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Tambah Barang'),
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
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                    _buildTextField(
                      _nama,
                      'Nama Barang',
                      Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_kode, 'Kode Barang', Icons.qr_code),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _jenis,
                      'Jenis Barang',
                      Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _stok,
                      'Jumlah Stok',
                      Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _harga,
                      'Harga',
                      Icons.price_change,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 18),

                    // Preview / info gambar
                    if (!kIsWeb && _selectedImage == null ||
                        kIsWeb && _webImage == null)
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
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loading ? null : _submit,
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
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
    );
  }
}
