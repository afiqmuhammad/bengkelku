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
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kode = TextEditingController();
  final _jenis = TextEditingController();
  final _stok = TextEditingController();
  final _harga = TextEditingController();

  XFile? _webImage; // untuk web
  File? _selectedImage; // untuk mobile
  bool _loading = false;

  final picker = ImagePicker();
  final uuid = const Uuid();

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Cek kode_barang sudah ada atau belum
      final existing =
          await Supabase.instance.client
              .from('barang')
              .select('id')
              .eq('kode_barang', _kode.text.trim())
              .maybeSingle();

      if (existing != null) {
        throw Exception(
          'Kode Barang sudah digunakan, silakan gunakan kode lain.',
        );
      }

      String? imageUrl;
      if ((kIsWeb && _webImage != null) ||
          (!kIsWeb && _selectedImage != null)) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('Gagal upload gambar');
        }
      }

      await Supabase.instance.client.from('barang').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'nama_barang': _nama.text.trim(),
        'kode_barang': _kode.text.trim(),
        'jenis_barang': _jenis.text.trim(),
        'jumlah_stok': int.parse(_stok.text.trim()),
        'harga': double.parse(_harga.text.trim()),
        'gambar_url': imageUrl,
      });

      setState(() => _loading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // sama seperti login
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
                boxShadow: [
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
                    // Tambahkan logo/icon di atas form
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png', // Ganti dengan path gambar kamu
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nama,
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.blue.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kode,
                      decoration: InputDecoration(
                        labelText: 'Kode Barang',
                        prefixIcon: Icon(
                          Icons.qr_code,
                          color: Colors.blue.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jenis,
                      decoration: InputDecoration(
                        labelText: 'Jenis Barang',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Colors.blue.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stok,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Stok',
                        prefixIcon: Icon(
                          Icons.numbers,
                          color: Colors.blue.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _harga,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga',
                        prefixIcon: Icon(
                          Icons.price_change,
                          color: Colors.blue.shade700,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
                    ),
                    const SizedBox(height: 18),
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
                      label: const Text("Pilih Gambar"),
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
                          elevation: 2,
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
}
