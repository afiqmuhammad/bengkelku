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
      query = query.gte('tanggal', start.toIso8601String());
      query = query.lt('tanggal', end.toIso8601String());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Riwayat Barang'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Tipe: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items:
                          ['Semua', 'Masuk', 'Keluar']
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: _onFilterChanged,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _selectedDate == null
                            ? 'Pilih Tanggal'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearDateFilter,
                        tooltip: 'Hapus Filter Tanggal',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Riwayat List
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
                    child: Text('Belum ada riwayat transaksi.'),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: warna.withOpacity(0.15),
                          child: Icon(
                            tipe == 'masuk'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: warna,
                          ),
                        ),
                        title: Text(
                          item['nama_barang'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kode: ${item['kode_barang']}'),
                            Text('Jenis: ${item['jenis_barang']}'),
                            Text('Jumlah: ${item['jumlah']}'),
                            Text(
                              'Total: Rp${item['total'].toStringAsFixed(0)}',
                            ),
                            Text('Tanggal: $tanggal'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                            ),
                          ),
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
}
