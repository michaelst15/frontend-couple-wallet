import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:couple_wallet/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FullDataController extends GetxController {
  // ✅ Data utama hasil login
  var fullData = <String, dynamic>{}.obs;

  // ✅ Loading state global
  var isLoading = false.obs;

  // ✅ Data rooms untuk pendaftaran
  var rooms = <Map<String, dynamic>>[].obs;

  // ✅ Base URL
  // final String baseUrl = "https://backend-couple-wallet-michaelst152166-1e8lpgte.apn.leapcell.dev";
  final String baseUrl = "https://f3bd8980dac9.ngrok-free.app";

  // ✅ Simpan data login
  // ✅ Simpan data login


  // ✅ Reactive transaksi & saldo
  var pemasukanHarian = <Map<String, dynamic>>[].obs;
  var pengeluaranHarian = <Map<String, dynamic>>[].obs;
  var totalRoomSaldo = 0.0.obs; // ✅ RxDouble supaya Obx auto-update
  var totalPemasukan = 0.0.obs;
  var totalPengeluaran = 0.0.obs;
  var totalPemasukanRoom = 0.0.obs;
  var totalPengeluaranRoom = 0.0.obs;
  var hasNewNotification = false.obs;
  var newDataList = <Map<String, dynamic>>[].obs;


  void setFullData(Map<String, dynamic> data) {
    fullData.value = Map<String, dynamic>.from(data);

    pemasukanHarian.value = (data['pemasukan_harian'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];
    pengeluaranHarian.value = (data['pengeluaran_harian'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];
    totalRoomSaldo.value = _toDouble(data['total_room_saldo']);

    totalPemasukanRoom.value = _toDouble(data['total_pemasukan_room']);
    totalPengeluaranRoom.value = _toDouble(data['total_pengeluaran_room']);
  }
  
  

    // Helper konversi
    double _toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }

    double toDoubleSafe(dynamic val) {
        if (val == null) return 0.0;
        if (val is num) return val.toDouble();
        if (val is String) {
          final clean = val.replaceAll(RegExp(r'[^0-9.-]'), '');
          return double.tryParse(clean) ?? 0.0;
        }
        return 0.0;
      }

    // Hitung total dari list transaksi
    void refreshTotals() {
      totalPemasukan.value =
          pemasukanHarian.fold(0.0, (sum, e) => sum + _toDouble(e['pemasukan']));
      totalPengeluaran.value =
          pengeluaranHarian.fold(0.0, (sum, e) => sum + _toDouble(e['pengeluaran']));
      totalRoomSaldo.value = totalPemasukan.value - totalPengeluaran.value;
    }

    // Panggil ini setiap kali data diperbarui
Future<void> refreshData({DateTime? selectedDate}) async {
  if (fullData['email'] != null && fullData['password'] != null) {
    try {
      isLoading.value = true;

      // 🔹 Format tanggal (jika ada)
      String? formattedDate;
      if (selectedDate != null) {
        formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      }

      // Simpan data lama untuk perbandingan
      final oldPemasukan = List<Map<String, dynamic>>.from(pemasukanHarian);
      final oldPengeluaran = List<Map<String, dynamic>>.from(pengeluaranHarian);

      // 🔹 Ambil data terbaru dari server
      // Jika API kamu bisa terima parameter tanggal, gunakan seperti ini:
      // final url = Uri.parse("$baseUrl/get-transaksi-lainnya?tanggal=$formattedDate");
      // await loadDataByTanggal(url);

      // Jika tidak, gunakan cara umum:
      await loadFullData(fullData['email'], fullData['password']);

      // 🔹 Filter data sesuai tanggal terpilih (jika ada)
      if (selectedDate != null) {
        pemasukanHarian.value = pemasukanHarian
            .where((trx) =>
                trx['tanggal_update'] != null &&
                DateTime.parse(trx['tanggal_update']).year == selectedDate.year &&
                DateTime.parse(trx['tanggal_update']).month == selectedDate.month &&
                DateTime.parse(trx['tanggal_update']).day == selectedDate.day)
            .toList();

        pengeluaranHarian.value = pengeluaranHarian
            .where((trx) =>
                trx['tanggal_update'] != null &&
                DateTime.parse(trx['tanggal_update']).year == selectedDate.year &&
                DateTime.parse(trx['tanggal_update']).month == selectedDate.month &&
                DateTime.parse(trx['tanggal_update']).day == selectedDate.day)
            .toList();
      }

      // ✅ Bandingkan apakah ada pemasukan baru
      bool adaPemasukanBaru = pemasukanHarian.any((p) =>
          !oldPemasukan.any((old) => jsonEncode(old) == jsonEncode(p)));

      // ✅ Bandingkan apakah ada pengeluaran baru
      bool adaPengeluaranBaru = pengeluaranHarian.any((p) =>
          !oldPengeluaran.any((old) => jsonEncode(old) == jsonEncode(p)));

      // 🔔 Tambahkan notifikasi baru jika ada perubahan
      if (adaPemasukanBaru) {
        hasNewNotification.value = true;
        newDataList.add({
          "judul": "Pemasukan Baru",
          "detail": "Ada pemasukan baru tercatat di sistem pada ${formattedDate ?? 'hari ini'}.",
        });
      }

      if (adaPengeluaranBaru) {
        hasNewNotification.value = true;
        newDataList.add({
          "judul": "Pengeluaran Baru",
          "detail": "Ada pengeluaran baru tercatat di sistem pada ${formattedDate ?? 'hari ini'}.",
        });
      }

      print("✅ Refresh data berhasil untuk tanggal ${formattedDate ?? 'semua tanggal'}");

    } catch (e) {
      print("❌ Error refreshData: $e");
    } finally {
      isLoading.value = false;
    }
  }
}



    void clearNotificationFlag() {
      hasNewNotification.value = false;
      newDataList.clear();
    }



  // =========================================================
  // 🔐 LOGIN
  // =========================================================
Future<void> loadFullData(String email, String password) async {
  try {
    isLoading.value = true;
    final url = Uri.parse("$baseUrl/login");

    print("🌐 Login ke $url");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"identifier": email, "password": password}),
    );

    print("📡 Status: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      fullData.value = Map<String, dynamic>.from(jsonResponse);
      setFullData(jsonResponse);

      // ✅ Update pemasukanHarian & pengeluaranHarian dari fullData
      pemasukanHarian.value = (jsonResponse['pemasukan_harian'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      pengeluaranHarian.value = (jsonResponse['pengeluaran_harian'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      refreshTotals();

      print("Login berhasil, data tersimpan di controller");
      print("PemasukanHarian: ${pemasukanHarian.length}, PengeluaranHarian: ${pengeluaranHarian.length}");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("Error loadFullData: $e");
    rethrow;
  } finally {
    isLoading.value = false;
  }
}


  // =========================================================
  // 🏠 LOAD ROOMS (untuk Register)
  // =========================================================
  Future<void> loadRooms() async {
    try {
      isLoading.value = true;
      final url = Uri.parse("$baseUrl/rooms");
      print("Mengambil daftar rooms dari $url");

      final response = await http.get(url);
      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<Map<String, dynamic>> parsedRooms = [];

        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              parsedRooms.add({
                "room_name": item["room_name"]?.toString() ?? "Room Tanpa Nama",
                "status": item["status"]?.toString() ?? "unknown",
              });
            }
          }
        }
        rooms.assignAll(parsedRooms);
        print("Rooms berhasil dimuat: ${rooms.length}");
      } else {
        throw Exception("Gagal memuat daftar room (${response.statusCode})");
      }
    } catch (e) {
      print("Error load Rooms: $e");
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // 📝 REGISTER
  // =========================================================
  Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String roomName,
    required BuildContext context,
  }) async {
    try {
      isLoading.value = true;

      final selected = rooms.firstWhereOrNull((r) => r["room_name"] == roomName);

      if (selected == null) {
        showPopup(context, "Room tidak ditemukan", false);
        return;
      }

      if (selected["status"] == "max") {
        showPopup(context, "Room sudah penuh", false);
        return;
      }

      final roomId = rooms.indexOf(selected) + 1;
      final url = Uri.parse("$baseUrl/register");

      print("Daftar user ke $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName.trim(),
          "email": email.trim(),
          "password": password.trim(),
          "confirm_password": confirmPassword.trim(),
          "room_id": roomId,
        }),
      );

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 201) {
        showPopup(context, "Berhasil daftar di $roomName", true);
        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(() => const LoginPage());
        return;
      }

      String failReason = "Gagal daftar";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey("message")) {
          final msg = decoded["message"].toString().toLowerCase();

          if (msg.contains("email")) {
            failReason = "Email sudah terdaftar";
          } else if (msg.contains("name") || msg.contains("nama")) {
            failReason = "Nama sudah digunakan";
          } else if (msg.contains("room")) {
            failReason = "Room sudah penuh atau tidak valid";
          } else {
            failReason = decoded["message"].toString();
          }
        } else {
          failReason = response.body.toString();
        }
      } catch (e) {
        print("Gagal parse error response: $e");
        failReason = "Gagal daftar (data tidak valid atau sudah digunakan)";
      }

      showPopup(context, failReason, false);
    } catch (e) {
      print("Error register User: $e");
      showPopup(context, "Terjadi kesalahan koneksi \n$e", false);
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================
  // 📸 OCR TRANSAKSI (PEMASUKAN & PENGELUARAN)
  // =========================================================
  Future<void> showUploadPopup(BuildContext context) async {
    final userId = fullData['user_id'];
    final roomId = fullData['room_id'];

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.single.bytes;
      if (fileBytes == null) return;

      final tempDir = Directory.systemTemp;
      final tempFile =
          await File('${tempDir.path}/temp_image.png').writeAsBytes(fileBytes);

      final inputImage = InputImage.fromFile(tempFile);
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final lines = recognizedText.blocks.expand((b) => b.lines).map((l) => l.text).toList();

      showOCRPopup(context, lines, userId, roomId);
    } catch (e) {
      print("Error show Upload Popup: $e");
      showPopup(context, "Gagal memproses gambar \n$e", false);
    }
  }

void showOCRPopup(BuildContext context, List<String> lines, int userId, int roomId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Keterangan Transaksi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines.map((line) {
                    return InkWell(
                      onTap: () {
                        // Tutup dialog pertama
                        Navigator.pop(dialogContext);

                        // Gunakan addPostFrameCallback untuk memastikan UI sudah selesai rebuild
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showNominalDetailPopup(context, line, userId, roomId);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(line, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48668),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Tutup", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}



Map<String, dynamic> extractAmountFromText(String text) {
  // Cari pola setelah Rp / RP
  final match = RegExp(r'rp[\s\.:]*([\d\.,]+)', caseSensitive: false).firstMatch(text);
  if (match == null) return {"display": "", "value": 0};

  String raw = match.group(1)!; // misal: "65.000,00"
  raw = raw.replaceAll(' ', '');

  // Normalisasi format Indonesia
  if (raw.contains(',') && raw.split(',').last.length <= 2) {
    raw = raw.split(',')[0];
  }

  final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
  final intValue = int.tryParse(cleaned) ?? 0;

  String formatWithDots(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return buffer.toString().split('').reversed.join();
  }

  final display = intValue > 0 ? formatWithDots(intValue) : "";

  return {"display": display, "value": intValue};
}



void showNominalDetailPopup(
    BuildContext context, String nominal, int userId, int roomId) {
  String selectedStatus = 'Pemasukan';
  bool isSending = false;

  final parsed = extractAmountFromText(nominal) ?? {"display": "", "value": 0};
  final cleanDisplay = parsed["display"]?.toString() ?? "";
  final shownText = cleanDisplay.isNotEmpty ? "Rp $cleanDisplay" : nominal;

  // Pastikan dialog dipanggil setelah frame berikutnya (aman dari context invalid)
  Future.delayed(const Duration(milliseconds: 100), () {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Detail Transaksi",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text("Nominal: $shownText", style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),

                    // Dropdown status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: selectedStatus,
                          items: ['Pemasukan', 'Pengeluaran']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedStatus = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Aksi
                    Row(
                    mainAxisAlignment: MainAxisAlignment.center, // buat button tetap berdekatan
                    children: [
                      SizedBox(
                        width: 120, // lebar button "Kirim"
                        height: 48, // tinggi button
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF48668),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isSending
                              ? null
                              : () async {
                                  setState(() => isSending = true);

                                  final sendNominal = cleanDisplay.isNotEmpty
                                      ? cleanDisplay
                                      : nominal;

                                  await _submitTransaction(
                                      dialogContext, selectedStatus, sendNominal, userId, roomId);

                                  setState(() => isSending = false);
                                },
                          child: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Kirim",
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8), // jarak tipis antar button
                      SizedBox(
                        width: 120, // lebar button "Tutup" sama dengan "Kirim"
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF48668),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            "Tutup",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  });
}






Future<void> _submitTransaction(
  BuildContext context,
  String status,
  String nominal,
  int userId,
  int roomId,
) async {
  final url = Uri.parse(
    status == 'Pemasukan'
        ? '$baseUrl/pemasukan'
        : '$baseUrl/pengeluaran',
  );

  // 🔹 Parsing nominal string → int
  int parseNominal(String nominal) {
    String cleaned = nominal.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  final amount = parseNominal(nominal);

  if (amount <= 0) {
    showPopup(context, "Nominal tidak valid atau kosong!", false);
    return;
  }

  try {
    final body = jsonEncode({
      'user_id': userId,
      'room_id': roomId,
      'amount': amount,
    });

    print("📤 Sending transaction: $body to $url");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print("📥 Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      // ✅ Tambahkan notifikasi lokal
      hasNewNotification.value = true;
      newDataList.add({
        "judul": status == 'Pemasukan'
            ? "Pemasukan Baru"
            : "Pengeluaran Baru",
        "detail":
            "Transaksi $status sebesar Rp$nominal berhasil ditambahkan.",
      });

      showPopup(context, "Transaksi berhasil dikirim!", true);
    } else {
      showPopup(
        context,
        "Gagal mengirim transaksi.\nKode: ${response.statusCode}\n${response.body}",
        false,
      );
    }
  } catch (e) {
    showPopup(context, "Kesalahan koneksi atau server tidak merespons.\n$e", false);
  }
}


Future<List<String>?> scanStruk() async {
  try {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return null;

    final inputImage = InputImage.fromFile(File(pickedFile.path));
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    // Cari semua pattern nominal seperti: Rp 12.000 atau Rp12.000,00
    final regex = RegExp(r'rp[\s\.:]*([\d\.,]+)', caseSensitive: false);
    final matches = regex.allMatches(recognizedText.text);

    // Ambil semua hasil pencarian ke dalam list
    List<String> results = matches.map((m) => m.group(0) ?? '').where((s) => s.isNotEmpty).toList();

    // Kalau tidak ada nominal, tetap tampilkan hasil teks OCR sebagai fallback
    if (results.isEmpty) {
      results = recognizedText.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return results.isNotEmpty ? results : null;
  } catch (e) {
    debugPrint("Gagal melakukan OCR: $e");
    return null;
  }
}


  // =========================================================
  // 💬 POPUP FEEDBACK
  // =========================================================
void showPopup(BuildContext context, String message, bool success) {
  double scale = 0; // nilai awal untuk animasi zoom-in dan zoom-out
  bool closing = false;

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        // Jalankan animasi zoom-in saat popup muncul
        Future.delayed(const Duration(milliseconds: 50), () {
          setState(() => scale = 1);
        });

        // Setelah 2 detik, jalankan animasi zoom-out lalu tutup
        Future.delayed(const Duration(seconds: 2), () async {
          if (!closing) {
            closing = true;
            setState(() => scale = 0);
            await Future.delayed(const Duration(milliseconds: 250));
            if (Get.isDialogOpen ?? false) Get.back();
          }
        });

        return Center(
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack,
            child: AnimatedOpacity(
              opacity: scale,
              duration: const Duration(milliseconds: 300),
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      success ? Icons.check_circle_outline : Icons.error_outline,
                      color: success ? Colors.green : Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      success ? "Berhasil \n$message" : "Gagal\n$message",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
    barrierDismissible: false,
  );
}



  Future<List<Map<String, dynamic>>> fetchTransaksi() async {
  if (fullData['user_id'] == null || fullData['room_id'] == null) return [];
  try {
    final uri = Uri.parse("$baseUrl/get-transaksi").replace(
      queryParameters: {
        "user_id": fullData['user_id'].toString(),
        "room_id": fullData['room_id'].toString(),
      },
    );

    final response = await http.get(uri);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["status"] == "success") {
      return List<Map<String, dynamic>>.from(data["transaksi"]);
    }
    return [];
  } catch (e) {
    print("Error Fetch Transaksi: $e");
    return [];
  }
}

// =========================================================
// 🔹 SIMPAN TRANSAKSI
// =========================================================
Future<bool> simpanTransaksi({
  required String jenis,
  required String kategori,
  required String nominal,
  String? keterangan,
}) async {
  if (fullData['user_id'] == null || fullData['room_id'] == null) return false;

  int parseNominal(String nominal) {
    String cleaned = nominal.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
    if (cleaned.contains(',')) cleaned = cleaned.split(',')[0];
    return int.tryParse(cleaned) ?? 0;
  }

  final body = {
    "user_id": fullData['user_id'],
    "room_id": fullData['room_id'],
    "jenis": jenis,
    "kategori": kategori,
    "nominal": parseNominal(nominal),
    "keterangan": keterangan ?? "",
  };

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/transaksi-lainnya"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    final success = response.statusCode == 200 && data["status"] == "success";

    if (success) {
      // ✅ Tambahkan notifikasi baru
      hasNewNotification.value = true;

      newDataList.add({
        "title": "Transaksi Baru",
        "message":
            "Transaksi $jenis (${kategori}) sebesar Rp ${parseNominal(nominal)} berhasil disimpan.",
        "timestamp": DateTime.now().toIso8601String(),
      });
    }

    return success;
  } catch (e) {
    print("Error Simpan Transaksi: $e");
    return false;
  }
}

// =========================================================
// 🔹 FETCH SELURUH TRANSAKSI (user_transactions + other_transaction)
// =========================================================
// RxList yang sudah ada
RxList<Map<String, dynamic>> seluruhTransaksi = <Map<String, dynamic>>[].obs;

 final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
final RxString selectedStatus = "Pemasukan".obs;

  // ===============================
  // 🔹 Ambil transaksi "other" per tanggal
  // ===============================
  List<Map<String, dynamic>> getOtherTransactionsByDate(DateTime date) {
    DateTime dateKey = DateTime(date.year, date.month, date.day);
    

    return seluruhTransaksi.where((trx) {
      if (trx['source'] != 'other' || trx['tanggal_update'] == null) return false;

      DateTime trxDate = DateTime.parse(trx['tanggal_update']);
      DateTime trxKey = DateTime(trxDate.year, trxDate.month, trxDate.day);

      return trxKey == dateKey;
    }).toList();
  }

  // ===============================
  // 🔹 Update transaksi 'other' berdasarkan tanggal
  // ===============================
  void updateTransaksiNonBank({
    required DateTime tanggal,
    required String status,
    required double nominalBaru,
  }) {
    DateTime dateKey = DateTime(tanggal.year, tanggal.month, tanggal.day);

    bool updated = false;

    for (int i = 0; i < seluruhTransaksi.length; i++) {
      var trx = seluruhTransaksi[i];

      if (trx['source'] == 'other' && trx['tanggal_update'] != null) {
        DateTime trxDate = DateTime.parse(trx['tanggal_update']);
        DateTime trxKey = DateTime(trxDate.year, trxDate.month, trxDate.day);

        if (trxKey == dateKey) {
          // 🔸 Update data transaksi
          seluruhTransaksi[i] = {
            ...trx,
            'nominal': nominalBaru,
            'jenis': status,
            'tanggal_update': tanggal.toIso8601String(),
          };
          updated = true;
        }
      }
    }

    // 🔸 Paksa RxList notifikasi ulang ke UI
    if (updated) {
      seluruhTransaksi.refresh(); // ⬅️ ini yang memicu UI update otomatis
      print("🔁 Transaksi non-bank tanggal $dateKey berhasil diperbarui.");
    } else {
      print("⚠️ Tidak ditemukan transaksi 'other' di tanggal $dateKey.");
    }
  }

  // ===============================
  // 🔹 Fetch seluruh transaksi dari server
  // ===============================
  Future<List<Map<String, dynamic>>> fetchSeluruhTransaksi() async {
    if (fullData['room_id'] == null) return [];

    try {
      final uri = Uri.parse("$baseUrl/seluruh-transaksi").replace(
        queryParameters: {
          "room_id": fullData['room_id'].toString(),
        },
      );

      print("🌐 Fetch Seluruh Transaksi: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success" && data["data"] != null) {
          List<Map<String, dynamic>> listTransaksi =
              List<Map<String, dynamic>>.from(data["data"]);

          // 🔹 Update RxList supaya UI reaktif
          seluruhTransaksi.value = listTransaksi;

          print("📦 Total transaksi: ${listTransaksi.length}");
          return listTransaksi;
        } else {
          print("⚠️ Response sukses tapi data kosong");
        }
      } else {
        print("❌ Gagal fetch seluruh transaksi: ${response.statusCode}");
      }

      // 🔹 Kosongkan jika gagal
      seluruhTransaksi.clear();
      return [];
    } catch (e) {
      print("Error fetchSeluruhTransaksi: $e");
      seluruhTransaksi.clear();
      return [];
    }
  }

// =========================================================
// ✏️ EDIT TRANSAKSI BY ID
// =========================================================
RxDouble totalSaldo = 0.0.obs;

Future<bool> editTransaksiByID({
  required int id,
  required String jenis,
  required double nominal,
  required BuildContext context,
}) async {
  final url = Uri.parse("$baseUrl/edit-transaksi-lainnya");

  try {
    final body = jsonEncode({
      "id": id,
      "jenis": jenis,
      "nominal": nominal,
    });

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ Tampilkan popup sukses
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 70),
                const SizedBox(height: 15),
                Text(
                  "Perubahan berhasil dilakukan",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF48668),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF48668),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );

      await refreshData();
      return true; // ✅ sukses
    } else {
      // ❌ Popup gagal karena status code bukan 200
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.redAccent, size: 70),
                const SizedBox(height: 15),
                Text(
                  "Perubahan gagal dilakukan (${response.statusCode})",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF48668),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
      return false;
    }
  } catch (e) {
    // ❌ Popup error network / server
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 70),
              const SizedBox(height: 15),
              Text(
                "Terjadi kesalahan: $e",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF48668),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
    return false;
  }
}

}

