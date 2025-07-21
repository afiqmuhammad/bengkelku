import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<dynamic>> _riwayatFuture;
  String _selectedFilter = 'Semua';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _riwayatFuture = _fetchRiwayat();
  }

  Future<List<dynamic>> _fetchRiwayat() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = supabase.from('riwayat_transaksi').select();

    if (_selectedFilter != 'Semua') {
      query = query.eq('tipe', _selectedFilter.toLowerCase());
    }

    if (_selectedDate != null) {
      final start = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final end = start.add(const Duration(days: 1));
      query = query
          .gte('tanggal', start.toIso8601String())
          .lt('tanggal', end.toIso8601String());
    }

    final data = await query.order('tanggal', ascending: false);
    return data;
  }

  void _onFilterChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedFilter = value;
      _riwayatFuture = _fetchRiwayat();
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _riwayatFuture = _fetchRiwayat();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _riwayatFuture = _fetchRiwayat();
    });
  }

  DropdownMenuItem<String> _buildDropdownItem(String label, IconData icon) {
    return DropdownMenuItem<String>(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D9CDB),
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
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Icon(Icons.history, size: 64, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  "Riwayat Barang",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'Tipe:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(10),
                              dropdownColor: Colors.white,
                              items: [
                                _buildDropdownItem('Semua', Icons.list_alt),
                                _buildDropdownItem(
                                  'Masuk',
                                  Icons.arrow_downward,
                                ),
                                _buildDropdownItem(
                                  'Keluar',
                                  Icons.arrow_upward,
                                ),
                              ],
                              onChanged: _onFilterChanged,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.date_range),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            label: Text(
                              _selectedDate == null
                                  ? 'Pilih Tanggal'
                                  : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate!),
                            ),
                          ),
                          if (_selectedDate != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              onPressed: _clearDateFilter,
                              tooltip: 'Hapus Filter Tanggal',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _riwayatFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal memuat data'));
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada riwayat transaksi.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = data[i];
                    final tipe = item['tipe'] as String;
                    final warna = tipe == 'masuk' ? Colors.green : Colors.red;
                    final tanggal = DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(DateTime.parse(item['tanggal']));

                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: warna.withOpacity(0.15),
                              radius: 24,
                              child: Icon(
                                tipe == 'masuk'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: warna,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_barang'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _buildDetailChip(
                                        'Kode',
                                        item['kode_barang'],
                                      ),
                                      _buildDetailChip(
                                        'Jenis',
                                        item['jenis_barang'],
                                      ),
                                      _buildDetailChip(
                                        'Jumlah',
                                        '${item['jumlah']}',
                                      ),
                                      _buildDetailChip(
                                        'Total',
                                        'Rp${item['total']}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tanggal,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: warna.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tipe.toUpperCase(),
                                style: TextStyle(
                                  color: warna,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
