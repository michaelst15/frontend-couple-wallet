import 'dart:io';
import 'package:couple_wallet/pages/controller/fullDataController.dart';
import 'package:couple_wallet/widgets/menu_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

class HomePageUtama extends StatefulWidget {
  final Map<String, dynamic> fullData;
  final int userId;
  final String userName;
  final String email;
  final int roomId;
  final String roomName;
  final List<String> members;
  final String? loginTime;
  final double totalPemasukanUser;
  final double totalPengeluaranUser;
  final double totalPemasukanRoom;
  final double totalPengeluaranRoom;
  final double totalRoomSaldo;
  final String tanggalBuatRoom;
  final String terakhirUpdate;
  final int totalTransaksi;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  HomePageUtama({
    super.key,
    required this.fullData,
    required this.userId,
    required this.userName,
    required this.email,
    required this.roomId,
    required this.roomName,
    required this.members,
    this.loginTime,
    required this.totalPemasukanUser,
    required this.totalPengeluaranUser,
    required this.totalPemasukanRoom,
    required this.totalPengeluaranRoom,
    required this.totalRoomSaldo,
    required this.tanggalBuatRoom,
    required this.terakhirUpdate,
    required this.totalTransaksi,
  });

  @override
  State<HomePageUtama> createState() => _HomePageState();
}

class _HomePageState extends State<HomePageUtama> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController chartController;
  late Animation<double> chartAnimation;

  final FullDataController controller = Get.put(FullDataController());

  List<String> capturedTransactions = [];
  List<FlSpot> pemasukanSpots = [];
  List<FlSpot> pengeluaranSpots = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();

    chartController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    chartAnimation = CurvedAnimation(parent: chartController, curve: Curves.easeOut)
      ..addListener(() => setState(() {}));
    chartController.forward();

    // Jika ada data pemasukan/pengeluaran di fullData, convert ke FlSpot
    final pemasukanList = controller.fullData['pemasukan_list'] ?? [];
    final pengeluaranList = controller.fullData['pengeluaran_list'] ?? [];
    pemasukanSpots = pemasukanList.map<FlSpot>((e) => FlSpot(e['x'].toDouble(), e['y'].toDouble())).toList();
    pengeluaranSpots = pengeluaranList.map<FlSpot>((e) => FlSpot(e['x'].toDouble(), e['y'].toDouble())).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    chartController.dispose();
    super.dispose();
  }

  

  String _formatTanggal(String tanggalStr) {
    try {
      final date = DateTime.parse(tanggalStr);
      const bulan = ["Jan","Feb","Mar","Apr","Mei","Jun","Jul","Agu","Sep","Okt","Nov","Des"];
      return "${date.day} ${bulan[date.month - 1]} ${date.year}";
    } catch (e) {
      return tanggalStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    String loginYear = "-";
    if (widget.loginTime != null && widget.loginTime!.isNotEmpty) {
      final parsed = DateTime.tryParse(widget.loginTime!);
      if (parsed != null) loginYear = parsed.year.toString();
    }
    

    return Scaffold(
      key: widget._scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => MainAppBar(
              title: "Dashboard",
              scaffoldKey: widget._scaffoldKey,
              hasNewData: controller.hasNewNotification.value,
              newDataList: controller.newDataList,
              onClearNotification: controller.clearNotificationFlag,
            )),
      ),

      backgroundColor: const Color(0xFFFEE9E1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info user
            Row(
              children: [
                const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('lib/image/couple.png'),
              ),

                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.members.isNotEmpty
                          ? widget.members.map((m) => m.split(" ")[0]).join(" & ")
                          : "Belum ada pasangan",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    Text("Bersama sejak $loginYear", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Saldo
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Transform(
                transform: Matrix4.translationValues(0, 50 * (1 - _animation.value), 0),
                child: child,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF48668),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Saldo Bersama", style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      "Rp ${widget.totalRoomSaldo.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text("Diperbarui: ${_formatTanggal(widget.terakhirUpdate)}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Statistik Keuangan
            Text(
                "Statistik Keuangan Via Struck",
                style: GoogleFonts.lobster(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 99, 98, 98),
                ),
              ),
              const SizedBox(height: 16),

              // Line Chart
              // Line Chart reactive
              AspectRatio(
                aspectRatio: 1.5,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
                            return Text(
                              days[value.toInt() % 7],
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            "Rp ${(value / 1000).toStringAsFixed(0)}k",
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // 🟢 Garis Pemasukan
                      LineChartBarData(
                        spots: List.generate(7, (index) {
                          double value = controller.totalPemasukanRoom * ((index + 1) / 7);
                          return FlSpot(index.toDouble(), value);
                        }),
                        isCurved: true,
                        color: Colors.greenAccent.shade400,
                        barWidth: 4,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.greenAccent.shade100.withOpacity(0.3),
                        ),
                      ),
                      // 🔴 Garis Pengeluaran
                      LineChartBarData(
                        spots: List.generate(7, (index) {
                          double value = controller.totalPengeluaranRoom * ((index + 1) / 7);
                          return FlSpot(index.toDouble(), value);
                        }),
                        isCurved: true,
                        color: Colors.redAccent.shade200,
                        barWidth: 4,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.redAccent.shade100.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),



              const SizedBox(height: 20),

              // 🔹 Kotak Ringkasan Pemasukan & Pengeluaran Room
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => _buildRoomSummaryCard(
                      "Pemasukan Room",
                      controller.totalPemasukanRoom.value,
                      Colors.green,
                    )),
                Obx(() => _buildRoomSummaryCard(
                      "Pengeluaran Room",
                      controller.totalPengeluaranRoom.value,
                      Colors.redAccent,
                    )),
              ],
            ),

              const SizedBox(height: 30),

            // Tombol Scan & Upload
            Center(
              child: Text(
                "Pemasukan dan Pengeluaran",
                style: GoogleFonts.lobster(fontSize: 20, fontWeight: FontWeight.w400, color: const Color.fromARGB(255, 99, 98, 98)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 Button Scan (kamera OCR)
              ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48668),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              onPressed: () async {
                final result = await controller.scanStruk(); // pakai kamera
                if (result != null) {
                  // langsung panggil popup transaksi dengan nominal hasil scan
                  controller.showNominalDetailPopup(
                    context,
                    result, 
                    controller.fullData['user_id'],
                    controller.fullData['room_id'],
                  );
                } else {
                  controller.showPopup(context, "Gagal scan struk 😢", false);
                }
              },
              icon: const Icon(Icons.qr_code_scanner, size: 24, color: Colors.white),
              label: const Text(
                "Scan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),


              const SizedBox(width: 20),

              // 🔹 Button Upload (pilih file struk)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF48668),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                onPressed: () async {
                  await controller.showUploadPopup(context);
                },
                icon: const Icon(Icons.upload_file, size: 24, color: Colors.white),
                label: const Text(
                  "Upload",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),


          ],
        ),
      ),
    );
  }
}

// Fungsi helper untuk membuat kotak summary room
Widget _buildRoomSummaryCard(String label, double amount, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 6),
          Text(
            "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: color, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}
