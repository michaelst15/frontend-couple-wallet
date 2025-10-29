import 'package:couple_wallet/pages/home.dart';
import 'package:couple_wallet/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/transaksi_page.dart';
import 'pages/laporan_page.dart';
import 'pages/pengaturan_page.dart';
import 'package:get/get.dart';
import 'pages/controller/fullDataController.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi controller hanya sekali
  if (!Get.isRegistered<FullDataController>()) {
    Get.put(FullDataController(), permanent: true);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Couple Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF48668)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String email;
  final int roomId;
  final List<dynamic>? members;
  final Map<String, dynamic>? fullData;
  final String? loginTime;
  final List<Map<String, dynamic>> pemasukanHarian;
  final List<Map<String, dynamic>> pengeluaranHarian;

  const MainPage({
    super.key,
    required this.pemasukanHarian,
    required this.pengeluaranHarian,
    required this.userId,
    required this.userName,
    required this.email,
    required this.roomId,
    this.members,
    this.fullData,
    this.loginTime,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FullDataController fullDataController = Get.find<FullDataController>();
  int _selectedIndex = 0;
  List<String> memberList = [];

  @override
  void initState() {
    super.initState();
    memberList = widget.members?.map((m) => m.toString()).toList() ?? [];

    if (widget.fullData != null && widget.fullData!.isNotEmpty) {
      fullDataController.setFullData(widget.fullData!);
    }

    debugPrint("✅ MainPage diinisialisasi dengan user: ${widget.userName}");
  }

  void _onTabChange(int index) async {
    setState(() => _selectedIndex = index);

    // Refresh data saat pindah tab
    final email = widget.email;
    final password = widget.fullData?["password"];
    if (email.isNotEmpty && password != null) {
      await fullDataController.loadFullData(email, password);
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = fullDataController.fullData;
      final roomName = data["room_name"] ?? "-";
      final tanggalBuatRoom = data["tanggal_buat_room"] ?? "-";
      final totalPemasukanRoom = _toDouble(data["total_pemasukan_room"]);
      final totalPengeluaranRoom = _toDouble(data["total_pengeluaran_room"]);
      final totalRoomSaldo = _toDouble(data["total_room_saldo"]);
      final pemasukanHarian = data["pemasukan_harian"] is List ? data["pemasukan_harian"] as List : <dynamic>[];
      final pengeluaranHarian = data["pengeluaran_harian"] is List ? data["pengeluaran_harian"] as List : <dynamic>[];

      double totalPemasukanUser = 0;
      double totalPengeluaranUser = 0;
      for (var p in pemasukanHarian) totalPemasukanUser += _toDouble(p["pemasukan"]);
      for (var p in pengeluaranHarian) totalPengeluaranUser += _toDouble(p["pengeluaran"]);

      final pages = [
        HomePageUtama(
          fullData: data,
          userId: widget.userId,
          userName: widget.userName,
          email: widget.email,
          roomId: widget.roomId,
          roomName: roomName,
          members: memberList,
          loginTime: widget.loginTime,
          totalPemasukanUser: totalPemasukanUser,
          totalPengeluaranUser: totalPengeluaranUser,
          totalPemasukanRoom: totalPemasukanRoom,
          totalPengeluaranRoom: totalPengeluaranRoom,
          totalRoomSaldo: totalRoomSaldo,
          tanggalBuatRoom: tanggalBuatRoom,
          terakhirUpdate: data["time"] ?? "-",
          totalTransaksi: pemasukanHarian.length + pengeluaranHarian.length,
        ),
        TransaksiPage(),
       LaporanPage(),
        PengaturanPage(),
      ];

      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFF48668),
          unselectedItemColor: Colors.grey,
          onTap: _onTabChange,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Transaksi'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
          ],
        ),
      );
    });
  }
}
