// ignore_for_file: use_build_context_synchronously

import 'dart:io';
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

  File? _selectedImage;
  bool _loading = false;

  final picker = ImagePicker();
  final uuid = const Uuid();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    final fileExt = image.path.split('.').last;
    final fileName = '${uuid.v4()}.$fileExt';
    final path = 'barang_images/$fileName';

    final bytes = await image.readAsBytes();
    final res = await Supabase.instance.client.storage
        .from('barang_images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

    if (res.isEmpty) return null;
    return Supabase.instance.client.storage
        .from('barang_images')
        .getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
              ),
              TextFormField(
                controller: _kode,
                decoration: const InputDecoration(labelText: 'Kode Barang'),
                validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
              ),
              TextFormField(
                controller: _jenis,
                decoration: const InputDecoration(labelText: 'Jenis Barang'),
                validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
              ),
              TextFormField(
                controller: _stok,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Stok'),
                validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
              ),
              TextFormField(
                controller: _harga,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
                validator: (v) => v!.isEmpty ? 'Harus diisi' : null,
              ),
              const SizedBox(height: 10),
              _selectedImage == null
                  ? const Text('Belum ada gambar')
                  : Image.file(_selectedImage!, height: 150),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
