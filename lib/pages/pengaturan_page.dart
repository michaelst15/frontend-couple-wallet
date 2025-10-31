import 'package:couple_wallet/pages/controller/fullDataController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:typewritertext/typewritertext.dart';
import '../widgets/menu_app_bar.dart';
import 'login.dart';

// 🟢 Tambahkan RouteObserver global agar bisa memantau perubahan route
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class PengaturanPage extends StatefulWidget {
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

  const PengaturanPage({
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
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage>
    with SingleTickerProviderStateMixin, RouteAware {
  final FullDataController controller = Get.find<FullDataController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _jumlahController = TextEditingController();

  late final AnimationController _lottieController;
  bool _showText = false;

  final String _fullText =
      "Atur dan kelola keuangan Anda secara realtime dengan mudah 💰";

  
  // Misal kita punya Map<DateTime, List<Map<String, dynamic>>> untuk kalender
Map<DateTime, List<Map<String, dynamic>>> otherTransactionsByDate = {};

// Setelah fetchSeluruhTransaksi
void _processOtherTransactions(List<Map<String, dynamic>> listTransaksi) {
  otherTransactionsByDate.clear(); // reset

  for (var trx in listTransaksi) {
    if (trx['source'] == 'other') {
      DateTime tanggal = DateTime.parse(trx['tanggal_update']);
      DateTime dateKey = DateTime(tanggal.year, tanggal.month, tanggal.day);

      if (!otherTransactionsByDate.containsKey(dateKey)) {
        otherTransactionsByDate[dateKey] = [];
      }
      otherTransactionsByDate[dateKey]!.add(trx);
    }
  }

  print("Transaksi 'other' berdasarkan tanggal:");
  otherTransactionsByDate.forEach((key, value) {
    print("$key : $value");
  });
}


  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    print(widget.members);

    // 🔹 Ambil seluruh transaksi saat init
    _fetchTransaksi();
  }

  @override
  void didPopNext() {
    super.didPopNext();

    // 🔹 Refresh transaksi saat kembali ke halaman Pengaturan
    _fetchTransaksi();

    _playTypeText();
  }

 void _fetchTransaksi() {
  controller.fetchSeluruhTransaksi().then((listTransaksi) {
    print("Seluruh transaksi berhasil diambil!");
    print(listTransaksi);

    // 🔹 Ambil data 'other' untuk kalender
    _processOtherTransactions(listTransaksi);
  }).catchError((err) {
    print("Gagal mengambil transaksi: $err");
  });
}


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    _playTypeText();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _lottieController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  void _playTypeText() {
    setState(() => _showText = false);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showText = true);
    });
  }

void _showUbahJumlahDialog() {
  String selectedStatus = "Pemasukan"; // default
  DateTime? selectedDate;
  final TextEditingController _jumlahController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final Color statusColor = selectedStatus == "Pemasukan"
              ? const Color(0xFFF48668)
              : Colors.redAccent;

          // Filter transaksi sesuai tanggal yang dipilih
          List<Map<String, dynamic>> transactionsForDate = [];
          if (selectedDate != null) {
            transactionsForDate = controller.seluruhTransaksi
                .where((trx) =>
                    trx['source'] == 'other' &&
                    trx['tanggal_update'] != null &&
                    DateTime.parse(trx['tanggal_update']).year ==
                        selectedDate!.year &&
                    DateTime.parse(trx['tanggal_update']).month ==
                        selectedDate!.month &&
                    DateTime.parse(trx['tanggal_update']).day ==
                        selectedDate!.day)
                .toList();
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Ubah Jumlah",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF48668),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Status
                  Row(
                    children: [
                      Text(
                        "Status:",
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: selectedStatus,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        items: ["Pemasukan", "Pengeluaran"]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedStatus = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Tanggal (Check)
                  Row(
                    children: [
                      Text(
                        "Tanggal:",
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          DateTime tempSelected = selectedDate ?? DateTime.now();
                          // Tampilkan kalender di tengah menggunakan dialog
                          final pickedDate = await showDialog<DateTime>(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: SizedBox(
                                      width: 350,
                                      height: 500,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Pilih Tanggal",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: TableCalendar(
                                              firstDay: DateTime(2020),
                                              lastDay: DateTime(2100),
                                              focusedDay: tempSelected,
                                              selectedDayPredicate: (day) => isSameDay(day, tempSelected),
                                              onDaySelected: (day, focusedDay) {
                                                setState(() {
                                                  tempSelected = day; // 🔹 Update tanggal terpilih
                                                });
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context, tempSelected);
                                              },
                                              child: const Text("Pilih"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );


                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              selectedDate != null
                                  ? "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}"
                                  : "Check",
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_drop_down, color: statusColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🔹 Input Jumlah
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Masukkan jumlah baru",
                      labelStyle: GoogleFonts.poppins(fontSize: 13.5),
                      prefixText: "Rp ",
                      prefixStyle: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: statusColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🔹 Daftar transaksi sesuai tanggal
                  if (transactionsForDate.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transaksi Non Bank:",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ...transactionsForDate.map((trx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              "${trx['jenis'] ?? trx['kategori']}: Rp ${trx['nominal'] ?? 0} — ${trx['keterangan'] ?? ''}",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 15),

                  // 🔹 Tombol Kirim & Tutup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final jumlah = _jumlahController.text.trim();
                            if (jumlah.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Masukkan jumlah terlebih dahulu"),
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Status: $selectedStatus | Jumlah: Rp $jumlah | Tanggal: ${selectedDate != null ? "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}" : "Belum dipilih"}",
                                ),
                              ),
                            );
                            Navigator.pop(context);
                            _jumlahController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Kirim",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _jumlahController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Tutup",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
}




void _showUbahJumlahBankDialog() {
  String selectedStatus = "Pemasukan";
  final TextEditingController _jumlahBankController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "Ubah Jumlah",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF48668),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Baris Status tanpa border
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Status:",
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: selectedStatus,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      items: ["Pemasukan", "Pengeluaran"]
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Input Jumlah dengan prefix Rp
                TextField(
                  controller: _jumlahBankController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Masukkan jumlah baru",
                    labelStyle: GoogleFonts.poppins(fontSize: 13.5),
                    prefixText: "Rp ",
                    prefixStyle: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFF48668), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 🔹 Tombol sejajar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Kirim
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final jumlah = _jumlahBankController.text.trim();
                          if (jumlah.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Masukkan jumlah terlebih dahulu"),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "BANK — Status: $selectedStatus | Jumlah: Rp $jumlah dikirim",
                              ),
                            ),
                          );
                          Navigator.pop(context);
                          _jumlahBankController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF48668),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Kirim",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Tombol Tutup
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _jumlahBankController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF48668),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "Tutup",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => MainAppBar(
              title: "Pengaturan",
              scaffoldKey: _scaffoldKey,
              hasNewData: controller.hasNewNotification.value,
              newDataList: controller.newDataList,
              onClearNotification: controller.clearNotificationFlag,
            )),
      ),
      backgroundColor: const Color(0xFFFEE9E1),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Pengaturan Aplikasi",
            style: GoogleFonts.abel(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 99, 98, 98),
            ),
          ),
          const SizedBox(height: 18),

          // 🔹 Row animasi + teks
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: AnimatedOpacity(
                  opacity: _showText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    height: 100,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade500.withOpacity(0.7),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: _showText
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: TypeWriter.text(
                              _fullText,
                              duration: const Duration(milliseconds: 60),
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(
                  'lib/animasi/finance.json',
                  controller: _lottieController,
                  repeat: true,
                  onLoaded: (composition) {
                    _lottieController
                      ..duration = composition.duration
                      ..repeat();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // 🔹 Menu Card 1 dengan popup
          _buildSettingCard(
            icon: Icons.credit_card,
            title: "Atur Pemasukan & Pengeluaran Non Bank",
            subtitle: "Ganti jumlah pemasukan & pengeluaran manual",
            onTap: _showUbahJumlahDialog,
          ),
          const SizedBox(height: 10),

            _buildSettingCard(
            icon: Icons.account_balance,
            title: "Atur Pemasukan & Pengeluaran Bank",
            subtitle: "Sesuaikan data keuangan dari rekening",
            onTap: _showUbahJumlahBankDialog,
          ),

          const SizedBox(height: 10),

          _buildSettingCard(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Keluar dari akun Anda",
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 25),

          // 🟢 Copyright Section
          Center(
            child: Column(
              children: [
                const Divider(thickness: 0.7),
                const SizedBox(height: 8),
                Text(
                  "© 2025 Couple Wallet",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Aplikasi pengelolaan keuangan pribadi dan pasangan untuk membantu\n"
                  "Anda memantau, mengatur, dan merencanakan keuangan bersama secara cerdas.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function() onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF48668), size: 28),
        title: Text(
          title,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15.5),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
