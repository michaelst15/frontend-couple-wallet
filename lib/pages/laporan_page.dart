import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/menu_app_bar.dart';
import '../pages/controller/fullDataController.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FullDataController controller = Get.find<FullDataController>();

  double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
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
    return Scaffold(
      key: _scaffoldKey,
     appBar: PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() => MainAppBar(
            title: "Laporan",
            scaffoldKey: _scaffoldKey,
            hasNewData: controller.hasNewNotification.value,
            newDataList: controller.newDataList,
            onClearNotification: controller.clearNotificationFlag,
          )),
    ),


      backgroundColor: const Color(0xFFFEE9E1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final pemasukanHarian = controller.pemasukanHarian;
          final pengeluaranHarian = controller.pengeluaranHarian;

          double totalPemasukan = pemasukanHarian.fold(
              0, (sum, e) => sum + _toDouble(e['pemasukan']));
          double totalPengeluaran = pengeluaranHarian.fold(
              0, (sum, e) => sum + _toDouble(e['pengeluaran']));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Ringkasan Keuangan
              Text(
                "Transaksi Non Bank",
                style: GoogleFonts.abel(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 99, 98, 98),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCard("Pemasukan", controller.totalPemasukan.value, Colors.green),
                      _buildSummaryCard("Pengeluaran", controller.totalPengeluaran.value, Colors.redAccent),
                      _buildSummaryCard("Saldo Bersih", controller.totalRoomSaldo.value, Colors.orange),
                    ],
                  );
                }),
              const SizedBox(height: 30),

              // 🔹 Grafik
              Text(
                "Perbandingan Pemasukan & Pengeluaran (Harian)",
                style: GoogleFonts.abel(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 99, 98, 98),
                ),
              ),
              const SizedBox(height: 16),
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
                          double value = totalPemasukan * ((index + 1) / 7);
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
                          double value = totalPengeluaran * ((index + 1) / 7);
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
              const SizedBox(height: 30),

              // 🔹 Rincian Laporan
              // 🔹 Rincian Laporan
                  Text(
                    "Rincian Laporan Pengguna",
                    style: GoogleFonts.abel(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 99, 98, 98),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Obx(() {
                    final pemasukanHarian = controller.pemasukanHarian;
                    final pengeluaranHarian = controller.pengeluaranHarian;
                    final semuaData = [
                      ...pemasukanHarian,
                      ...pengeluaranHarian,
                    ];

                    if (semuaData.isEmpty) {
                      // 📨 Tidak ada data transaksi
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.inbox, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                "Belum ada transaksi",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // 🔁 Jika lebih dari 3 data, buat scrollable container
                    final isScrollable = semuaData.length > 3;
                    final visibleHeight = isScrollable ? 350.0 : null;

                    // Tambahkan controller untuk scroll internal
                    final ScrollController innerScrollController = ScrollController();

                    final content = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...pemasukanHarian.map((item) {
                          final val = _parseDouble(item['pemasukan']);
                          final tanggal = item['tanggal']?.toString() ?? "-";
                          return _buildDetailCardWithIcon(
                            icon: Icons.arrow_downward_rounded,
                            iconColor: Colors.green,
                            title: "Pemasukan: $tanggal",
                            value: val,
                            color: Colors.green,
                          );
                        }).toList(),
                        ...pengeluaranHarian.map((item) {
                          final val = _parseDouble(item['pengeluaran']);
                          final tanggal = item['tanggal']?.toString() ?? "-";
                          return _buildDetailCardWithIcon(
                            icon: Icons.arrow_upward_rounded,
                            iconColor: Colors.redAccent,
                            title: "Pengeluaran: $tanggal",
                            value: val,
                            color: Colors.redAccent,
                          );
                        }).toList(),
                      ],
                    );

                    if (isScrollable) {
                      // 🧭 Batasi tinggi dan beri ScrollController sendiri
                      return Container(
                        constraints: BoxConstraints(maxHeight: visibleHeight!),
                        child: Scrollbar(
                          controller: innerScrollController,
                          thumbVisibility: true,
                          radius: const Radius.circular(10),
                          child: SingleChildScrollView(
                            controller: innerScrollController,
                            child: content,
                          ),
                        ),
                      );
                    } else {
                      // ✨ Kalau data <= 3, tampilkan biasa
                      return content;
                    }
                  }),



            ],
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            )),
          const SizedBox(height: 6),
          Text(
            "Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCardWithIcon({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp ${value.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]}.',
                  )}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
