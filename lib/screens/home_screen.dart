import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan warna latar belakang yang sama dengan RegisterScreen
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        // Menyesuaikan AppBar agar lebih cocok dengan tema
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        title: const Text(
          'Bengkel Stecu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Arahkan ke halaman login saat logout
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menambahkan judul dan subjudul seperti di RegisterScreen
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Menu Utama",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Pilih salah satu menu di bawah ini",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            // GridView untuk menu
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _menuItem(
                    context,
                    Icons.add_box,
                    'Tambah Barang',
                    '/tambah-barang',
                  ),
                  _menuItem(
                    context,
                    Icons.list,
                    'Daftar Barang',
                    '/daftar-barang',
                  ),
                  _menuItem(context, Icons.history, 'Riwayat', '/riwayat'),
                  _menuItem(context, Icons.bar_chart, 'Laporan', '/laporan'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk setiap item menu dengan gaya yang diperbarui
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      // Menggunakan dekorasi yang sama dengan kontainer di RegisterScreen
      child: Container(
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mengubah warna ikon agar sesuai
              Icon(icon, size: 48, color: Colors.blue.shade700),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
