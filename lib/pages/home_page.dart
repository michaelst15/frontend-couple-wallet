import 'package:couple_wallet/pages/controller/fullDataController.dart';
import 'package:couple_wallet/pages/laporan_page.dart';
import 'package:couple_wallet/pages/pengaturan_page.dart';
import 'package:couple_wallet/pages/transaksi_page.dart';
import 'package:couple_wallet/pages/home.dart';
import 'package:couple_wallet/widgets/menu_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String email;
  final int roomId;
  final List<dynamic>? members;
  final Map<String, dynamic>? fullData;
  final String? loginTime;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.email,
    required this.roomId,
    this.members,
    this.fullData,
    this.loginTime,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FullDataController fullDataController = Get.find<FullDataController>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // ✅ Simpan data awal hasil login (kalau ada)
    if (widget.fullData != null && widget.fullData!.isNotEmpty) {
      fullDataController.setFullData(widget.fullData!);
    }

    // ✅ (Opsional) Ambil data terbaru setelah login
    Future.microtask(() async {
      final email = widget.email;
      final password = widget.fullData?["password"];
      if (email.isNotEmpty && password != null) {
        await fullDataController.loadFullData(email, password);
      }
    });
  }

void _onTabTapped(int index) async {
  setState(() => _selectedIndex = index);

  // Panggil refresh data saat pindah ke page tertentu
  if (index == 0) { // misal Dashboard
    final email = widget.email;
    final password = widget.fullData?["password"];
    if (email.isNotEmpty && password != null) {
      await fullDataController.loadFullData(email, password);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fullData = fullDataController.fullData;
      final isLoading = fullDataController.isLoading.value;

      final pages = [
        HomePageUtama(
          fullData: fullData,
          userId: widget.userId,
          userName: widget.userName,
          email: widget.email,
          roomId: widget.roomId,
          roomName: fullData["room_name"] ?? "-",
          members: widget.members?.map((m) => m.toString()).toList() ?? [],
          loginTime: widget.loginTime ?? "-",
          totalPemasukanUser: fullData["total_pemasukan_user"] ?? 0,
          totalPengeluaranUser: fullData["total_pengeluaran_user"] ?? 0,
          totalPemasukanRoom: fullData["total_pemasukan_room"] ?? 0,
          totalPengeluaranRoom: fullData["total_pengeluaran_room"] ?? 0,
          totalRoomSaldo: fullData["total_room_saldo"] ?? 0,
          totalTransaksi: fullData["total_transaksi"] ?? 0,
          tanggalBuatRoom: fullData["tanggal_buat_room"] ?? "-",
          terakhirUpdate: fullData["time"] ?? "-",
        ),
        TransaksiPage(),
        LaporanPage(),
       PengaturanPage(
          fullData: fullData,
          userId: widget.userId,
          userName: widget.userName,
          email: widget.email,
          roomId: widget.roomId,
          roomName: fullData["room_name"] ?? "-",
          members: widget.members?.map((m) => m.toString()).toList() ?? [],
          loginTime: widget.loginTime ?? "-",
          totalPemasukanUser: fullData["total_pemasukan_user"] ?? 0,
          totalPengeluaranUser: fullData["total_pengeluaran_user"] ?? 0,
          totalPemasukanRoom: fullData["total_pemasukan_room"] ?? 0,
          totalPengeluaranRoom: fullData["total_pengeluaran_room"] ?? 0,
          totalRoomSaldo: fullData["total_room_saldo"] ?? 0,
          totalTransaksi: fullData["total_transaksi"] ?? 0,
          tanggalBuatRoom: fullData["tanggal_buat_room"] ?? "-",
          terakhirUpdate: fullData["time"] ?? "-",
       ),
      ];

      return Scaffold(
        appBar: MainAppBar(
          title: ["Dashboard", "Transaksi", "Laporan", "Pengaturan"][_selectedIndex],
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
        backgroundColor: const Color(0xFFFEE9E1),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFF48668),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "Transaksi"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Laporan"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Pengaturan"),
          ],
        ),
      );
    });
  }
}
