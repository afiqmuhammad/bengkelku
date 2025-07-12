// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;

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
    if (userId == null) return {'pendapatan': 0, 'transaksi': [], 'grafik': {}};

    var query = supabase
        .from('riwayat_transaksi')
        .select()
        .eq('user_id', userId);

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

    final pendapatanData = await supabase
        .from('transaksi')
        .select('total, tanggal, tipe')
        .eq('user_id', userId)
        .eq('tipe', 'keluar')
        .order('tanggal', ascending: true);

    num pendapatan = 0;
    Map<String, num> grafik = {};

    for (final item in pendapatanData) {
      final tgl = DateTime.parse(item['tanggal']);
      final tanggalStr = DateFormat('dd/MM').format(tgl);
      if (_selectedDate != null &&
          (tgl.isBefore(_selectedDate!) ||
              tgl.isAfter(_selectedDate!.add(const Duration(days: 1))))) {
        continue;
      }
      pendapatan += (item['total'] ?? 0);
      grafik[tanggalStr] = (grafik[tanggalStr] ?? 0) + (item['total'] ?? 0);
    }

    final transaksi = await query.order('tanggal', ascending: false);
    return {'pendapatan': pendapatan, 'transaksi': transaksi, 'grafik': grafik};
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

    // Muat logo dari asset
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Center(child: pw.Image(logoImage, height: 60)),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Laporan Transaksi',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total Pendapatan: Rp${pendapatan.toStringAsFixed(0)}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['No', 'Tanggal', 'Barang', 'Tipe', 'Jumlah', 'Total'],
                data: List.generate(transaksi.length, (index) {
                  final item = transaksi[index];
                  final tanggal =
                      item['tanggal'] != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(item['tanggal']))
                          : '-';
                  return [
                    '${index + 1}',
                    tanggal,
                    item['nama_barang'] ?? '-',
                    (item['tipe'] ?? '').toString().toUpperCase(),
                    '${item['jumlah'] ?? '-'}',
                    'Rp${item['total'] ?? '-'}',
                  ];
                }),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
            ],
      ),
    );

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final saveDir =
        await downloadsDir.exists()
            ? downloadsDir
            : await getApplicationDocumentsDirectory();
    final filePath =
        '${saveDir.path}/laporan_bengkel_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF berhasil disimpan:\n$filePath')),
      );
    }
  }

  List<BarChartGroupData> _generateBarChartData(Map<String, num> grafik) {
    final sortedKeys =
        grafik.keys.toList()..sort(
          (a, b) => DateFormat(
            'dd/MM',
          ).parse(a).compareTo(DateFormat('dd/MM').parse(b)),
        );

    return sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: grafik[key]!.toDouble(), color: Colors.green),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          // 🔵 Header dengan gradasi biru, tombol atas, dan ikon besar di tengah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 5,
              left: 10,
              right: 10,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade900],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Tombol back & print di kanan kiri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(5),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(5),
                      icon: const Icon(Icons.print, color: Colors.white),
                      onPressed: () async {
                        final data = await _laporanFuture;
                        await _printLaporan(context, data);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.bar_chart, color: Colors.blue, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Laporan Transaksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Filter tanggal
          Padding(
            padding: const EdgeInsets.all(16),
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

          // 📊 Konten laporan
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _laporanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data!;
                final pendapatan = data['pendapatan'] ?? 0;
                final grafik = Map<String, num>.from(data['grafik']);
                final transaksi = data['transaksi'] ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.green.shade50,
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
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (grafik.isNotEmpty) ...[
                        const Text(
                          'Grafik Transaksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              barGroups: _generateBarChartData(grafik),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 48,
                                    interval: 100000, // hanya tampil tiap 100rb
                                    getTitlesWidget: (value, _) {
                                      return Text(
                                        '${(value ~/ 1000)}k',
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.right,
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final keys = grafik.keys.toList();
                                      return value.toInt() >= keys.length
                                          ? const SizedBox()
                                          : Text(
                                            keys[value.toInt()],
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        'Semua Transaksi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      transaksi.isEmpty
                          ? const Text('Belum ada transaksi.')
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('No')),
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Barang')),
                                DataColumn(label: Text('Tipe')),
                                DataColumn(label: Text('Jumlah')),
                                DataColumn(label: Text('Total')),
                              ],
                              rows: List.generate(transaksi.length, (index) {
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
                                    DataCell(Text(item['nama_barang'] ?? '-')),
                                    DataCell(
                                      Text(
                                        tipe.toUpperCase(),
                                        style: TextStyle(color: warna),
                                      ),
                                    ),
                                    DataCell(Text('${item['jumlah'] ?? '-'}')),
                                    DataCell(Text('Rp${item['total'] ?? '-'}')),
                                  ],
                                );
                              }),
                            ),
                          ),
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
