import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../widgets/menu_app_bar.dart';
import './controller/fullDataController.dart'; // pastikan path sesuai

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  String _jenisTransaksi = "Pemasukan";
  String _kategori = "Makanan";

  final FullDataController controller = Get.find<FullDataController>();

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _simpanTransaksi() async {
    if (!_formKey.currentState!.validate()) return;

    Get.dialog(
      Center(
        child: CircularProgressIndicator(color: const Color(0xFFF48668)),
      ),
      barrierDismissible: false,
    );

    final success = await controller.simpanTransaksi(
      jenis: _jenisTransaksi,
      kategori: _kategori,
      nominal: _nominalController.text,
      keterangan: _keteranganController.text,
    );

    Navigator.of(context).pop(); // tutup loading

    Get.dialog(
      ZoomPopup(
        success: success,
        message: success ? "Transaksi berhasil!" : "Gagal menyimpan transaksi",
      ),
      barrierDismissible: true,
    );

    if (success) {
      _nominalController.clear();
      _keteranganController.clear();
      setState(() {}); // refresh FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() => MainAppBar(
            title: "Transaksi",
            scaffoldKey: scaffoldKey,
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
            Text(
              "Tambah Transaksi",
              style: GoogleFonts.abel(
                  fontSize: 20, fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 99, 98, 98)),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _jenisTransaksi,
                    items: const [
                      DropdownMenuItem(value: "Pemasukan", child: Text("Pemasukan")),
                      DropdownMenuItem(value: "Pengeluaran", child: Text("Pengeluaran")),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Jenis Transaksi",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => setState(() => _jenisTransaksi = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _kategori,
                    items: const [
                      DropdownMenuItem(value: "Makanan", child: Text("Makanan")),
                      DropdownMenuItem(value: "Belanja", child: Text("Belanja")),
                      DropdownMenuItem(value: "Hiburan", child: Text("Hiburan")),
                      DropdownMenuItem(value: "Tagihan", child: Text("Tagihan")),
                      DropdownMenuItem(value: "Lainnya", child: Text("Lainnya")),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => setState(() => _kategori = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Nominal",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Masukkan nominal";
                      if (double.tryParse(value) == null) return "Masukkan angka valid";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keteranganController,
                    decoration: const InputDecoration(
                      labelText: "Keterangan",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _simpanTransaksi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF48668),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Simpan Transaksi",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Transaksi Terakhir",
              style: GoogleFonts.abel(
                  fontSize: 20, fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 99, 98, 98)),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: controller.fetchTransaksi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Belum ada transaksi", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                final transaksiList = snapshot.data!;

                  // Hitung tinggi container berdasarkan jumlah item
                  final bool bisaScroll = transaksiList.length > 3;
                  final double containerHeight = bisaScroll ? 300 : transaksiList.length * 90;

                  return Container(
                    constraints: BoxConstraints(
                      maxHeight: containerHeight, // Batasi tinggi maksimal
                    ),
                    child: Scrollbar(
                      thumbVisibility: bisaScroll, // tampilkan scrollbar hanya kalau perlu
                      radius: const Radius.circular(8),
                      child: ListView.builder(
                        physics: bisaScroll
                            ? const BouncingScrollPhysics() // bisa di-scroll
                            : const NeverScrollableScrollPhysics(), // tidak di-scroll
                        shrinkWrap: true,
                        itemCount: transaksiList.length,
                        itemBuilder: (context, index) {
                          final tx = transaksiList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                tx["jenis"] == "Pemasukan"
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx["jenis"] == "Pemasukan" ? Colors.green : Colors.red,
                              ),
                              title: Text(
                                "${tx["kategori"]} - Rp ${tx["nominal"]}",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx["keterangan"] ?? "",
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tanggal: ${DateTime.parse(tx["tanggal_update"]).toLocal().toIso8601String().substring(0, 10)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );

              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- ZoomPopup tetap sama ---
class ZoomPopup extends StatelessWidget {
  final bool success;
  final String message;
  const ZoomPopup({super.key, required this.success, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(success ? Icons.check_circle_outline : Icons.error_outline,
                  color: success ? Colors.green : Colors.red, size: 60),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF48668),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
