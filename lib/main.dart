import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tambah_barang_screen.dart';
import 'screens/home_screen.dart';
import 'screens/daftar_barang_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/laporan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bengkelku',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner:
          false, // <-- ini untuk hilangkan tulisan DEBUG
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/tambah-barang': (context) => const TambahBarangScreen(),
        '/home': (context) => const HomeScreen(),
        '/daftar-barang': (context) => const DaftarBarangScreen(),
        '/riwayat': (context) => const RiwayatScreen(),
        '/laporan': (context) => const LaporanScreen(),
      },
    );
  }
}
