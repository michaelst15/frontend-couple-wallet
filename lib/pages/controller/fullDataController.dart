import 'dart:convert';
import 'dart:io';
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
  final String baseUrl = "https://backend-couple-wallet-michaelst152166-1e8lpgte.apn.leapcell.dev";

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
 Future<void> refreshData() async {
  if (fullData['email'] != null && fullData['password'] != null) {
    try {
      isLoading.value = true;

      final oldPemasukanCount = pemasukanHarian.length;
      final oldPengeluaranCount = pengeluaranHarian.length;

      await loadFullData(fullData['email'], fullData['password']);
      refreshTotals();

      // ✅ Deteksi data baru
          if (pemasukanHarian.length > oldPemasukanCount) {
            hasNewNotification.value = true;
            newDataList.add({
              "judul": "Pemasukan Baru",
              "detail": "Ada pemasukan baru tercatat di sistem.",
            });
          }

          if (pengeluaranHarian.length > oldPengeluaranCount) {
            hasNewNotification.value = true;
            newDataList.add({
              "judul": "Pengeluaran Baru",
              "detail": "Ada pengeluaran baru tercatat di sistem.",
            });
          }
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

      print("✅ Login berhasil, data tersimpan di controller");
      print("📊 PemasukanHarian: ${pemasukanHarian.length}, PengeluaranHarian: ${pengeluaranHarian.length}");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error loadFullData: $e");
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
      print("🌐 Mengambil daftar rooms dari $url");

      final response = await http.get(url);
      print("📡 Status: ${response.statusCode}");

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
        print("✅ Rooms berhasil dimuat: ${rooms.length}");
      } else {
        throw Exception("Gagal memuat daftar room (${response.statusCode})");
      }
    } catch (e) {
      print("❌ Error loadRooms: $e");
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
        showPopup(context, "Room tidak ditemukan 💔", false);
        return;
      }

      if (selected["status"] == "max") {
        showPopup(context, "Room sudah penuh 💔", false);
        return;
      }

      final roomId = rooms.indexOf(selected) + 1;
      final url = Uri.parse("$baseUrl/register");

      print("🚀 Daftar user ke $url");
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

      print("📡 Status: ${response.statusCode}");
      print("📦 Response: ${response.body}");

      if (response.statusCode == 201) {
        showPopup(context, "Berhasil daftar di $roomName 💞", true);
        await Future.delayed(const Duration(seconds: 2));
        Get.offAll(() => const LoginPage());
        return;
      }

      String failReason = "Gagal daftar 💔";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey("message")) {
          final msg = decoded["message"].toString().toLowerCase();

          if (msg.contains("email")) {
            failReason = "Email sudah terdaftar 💔";
          } else if (msg.contains("name") || msg.contains("nama")) {
            failReason = "Nama sudah digunakan 💔";
          } else if (msg.contains("room")) {
            failReason = "Room sudah penuh atau tidak valid 💔";
          } else {
            failReason = decoded["message"].toString();
          }
        } else {
          failReason = response.body.toString();
        }
      } catch (e) {
        print("⚠️ Gagal parse error response: $e");
        failReason = "Gagal daftar (data tidak valid atau sudah digunakan)";
      }

      showPopup(context, failReason, false);
    } catch (e) {
      print("❌ Error registerUser: $e");
      showPopup(context, "Terjadi kesalahan koneksi 😢\n$e", false);
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
      print("❌ Error showUploadPopup: $e");
      showPopup(context, "Gagal memproses gambar 😢\n$e", false);
    }
  }

void showOCRPopup(BuildContext context, List<String> lines, int userId, int roomId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Hasil OCR",
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
                        Navigator.pop(context);
                        showNominalDetailPopup(context, line, userId, roomId);
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
              onPressed: () => Navigator.pop(context),
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



void showNominalDetailPopup(BuildContext context, String nominal, int userId, int roomId) {
  String selectedStatus = 'Pemasukan';
  bool isSending = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
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
              Text("Nominal: $nominal", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedStatus,
                    items: ['Pemasukan', 'Pengeluaran']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Ubah dari Column menjadi Row untuk tombol
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF48668),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSending
                        ? null
                        : () async {
                            setState(() => isSending = true);
                            await _submitTransaction(context, selectedStatus, nominal, userId, roomId);
                            setState(() => isSending = false);
                          },
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Kirim", style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Future<void> _submitTransaction(
      BuildContext context, String status, String nominal, int userId, int roomId) async {
    final url = Uri.parse(status == 'Pemasukan' ? '$baseUrl/pemasukan' : '$baseUrl/pengeluaran');

    int parseNominal(String nominal) {
      String cleaned = nominal.replaceAll(RegExp(r'[^\d,]'), '').replaceAll('.', '');
      if (cleaned.contains(',')) cleaned = cleaned.split(',')[0];
      return int.tryParse(cleaned) ?? 0;
    }

    final amount = parseNominal(nominal);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'room_id': roomId, 'amount': amount}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showPopup(context, "Transaksi berhasil dikirim!", true);
      } else {
        showPopup(context, "Gagal kirim transaksi 💔\n${response.body}", false);
      }
    } catch (e) {
      showPopup(context, "Kesalahan koneksi 😢\n$e", false);
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
    final regex = RegExp(r'Rp\s?[0-9\.\,]+');
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
    debugPrint("❌ Gagal melakukan OCR: $e");
    return null;
  }
}


  // =========================================================
  // 💬 POPUP FEEDBACK
  // =========================================================
  void showPopup(BuildContext context, String message, bool success) {
    Get.dialog(
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(success ? Icons.check_circle_outline : Icons.error_outline,
                      color: success ? Colors.green : Colors.redAccent, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    success ? "Berhasil 🎉\n$message" : "Gagal ❌\n$message",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("OK",
                      style: TextStyle(color: Color(0xFFF48668), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
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
    print("❌ Error fetchTransaksi: $e");
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
    return response.statusCode == 200 && data["status"] == "success";
  } catch (e) {
    print("❌ Error simpanTransaksi: $e");
    return false;
  }
}
}
