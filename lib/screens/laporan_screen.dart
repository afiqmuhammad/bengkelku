import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  late Future<Map<String, dynamic>> _laporanFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _laporanFuture = _fetchLaporan();
  }

  Future<Map<String, dynamic>> _fetchLaporan() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {'pendapatan': 0, 'transaksi': []};

    // Filter tanggal jika ada
    var query = supabase.from('transaksi').select().eq('user_id', userId);

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

    // Hitung total pendapatan (total transaksi keluar)
    final pendapatanData = await supabase
        .from('transaksi')
        .select('total, tanggal, tipe')
        .eq('user_id', userId)
        .eq('tipe', 'keluar')
        .order('tanggal', ascending: false);

    num pendapatan = 0;
    for (final item in pendapatanData) {
      if (_selectedDate != null) {
        final tgl = DateTime.parse(item['tanggal']);
        if (tgl.isAfter(_selectedDate!.add(const Duration(days: 1))) ||
            tgl.isBefore(_selectedDate!))
          continue;
      }
      pendapatan += (item['total'] ?? 0);
    }

    // Ambil semua transaksi
    final transaksi = await query.order('tanggal', ascending: false);

    return {'pendapatan': pendapatan, 'transaksi': transaksi};
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
        _laporanFuture = _fetchLaporan();
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _laporanFuture = _fetchLaporan();
    });
  }

  Future<void> _printLaporan(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();
    final pendapatan = data['pendapatan'] ?? 0;
    final transaksi = data['transaksi'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                'Laporan Transaksi',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total Pendapatan: Rp${pendapatan.toStringAsFixed(0)}',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['No', 'Tanggal', 'Tipe', 'Jumlah', 'Total'],
                data: List<List<String>>.generate(transaksi.length, (index) {
                  final item = transaksi[index];
                  final tipe = (item['tipe'] ?? '').toString().toUpperCase();
                  final tanggal =
                      item['tanggal'] != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(item['tanggal']))
                          : '-';
                  return [
                    '${index + 1}',
                    tanggal,
                    tipe,
                    '${item['jumlah'] ?? '-'}',
                    'Rp${item['total'] ?? '-'}',
                  ];
                }),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
              ),
            ],
      ),
    );

    // Simpan ke file
    final output = await getExternalStorageDirectory();
    final filePath =
        '${output!.path}/laporan_bengkelku_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Tampilkan notifikasi/snackbar lokasi file
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF berhasil disimpan di:\n$filePath')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Laporan',
            onPressed: () async {
              final data = await _laporanFuture;
              await _printLaporan(context, data);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _selectedDate == null
                          ? 'Filter Tanggal'
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    ),
                    onPressed: _pickDate,
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearDate,
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _laporanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat laporan: ${snapshot.error}'),
                  );
                }
                final data = snapshot.data ?? {};
                final pendapatan = data['pendapatan'] ?? 0;
                final transaksi = data['transaksi'] ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.green.shade50,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.attach_money,
                            color: Colors.green,
                            size: 36,
                          ),
                          title: const Text(
                            'Total Pendapatan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Rp${pendapatan.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Semua Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tabel Transaksi
                      transaksi.isEmpty
                          ? const Center(child: Text('Belum ada transaksi.'))
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('No')),
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Tipe')),
                                DataColumn(label: Text('Jumlah')),
                                DataColumn(label: Text('Total')),
                              ],
                              rows: List<DataRow>.generate(transaksi.length, (
                                index,
                              ) {
                                final item = transaksi[index];
                                final tipe = item['tipe'] ?? '';
                                final warna =
                                    tipe == 'masuk' ? Colors.green : Colors.red;
                                final tanggal =
                                    item['tanggal'] != null
                                        ? DateFormat('dd/MM/yyyy').format(
                                          DateTime.parse(item['tanggal']),
                                        )
                                        : '-';
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${index + 1}')),
                                    DataCell(Text(tanggal)),
                                    DataCell(
                                      Text(
                                        tipe.toUpperCase(),
                                        style: TextStyle(
                                          color: warna,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text('${item['jumlah'] ?? '-'}')),
                                    DataCell(Text('Rp${item['total'] ?? '-'}')),
                                  ],
                                );
                              }),
                            ),
                          ),
                      const SizedBox(height: 24),
                      // ...existing ListView/separated jika ingin tetap ada...
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
