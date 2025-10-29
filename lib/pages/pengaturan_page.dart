import 'package:couple_wallet/pages/controller/fullDataController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/menu_app_bar.dart';
import 'login.dart'; // pastikan import LoginPage

class PengaturanPage extends StatelessWidget {
  PengaturanPage({super.key});
  final FullDataController controller = Get.find<FullDataController>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
          Text("Pengaturan Aplikasi",
              style: GoogleFonts.lobster(
                  fontSize: 20, 
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 99, 98, 98),
                  )),
          const SizedBox(height: 20),

          // Profil Pasangan
          _buildSettingCard(
            icon: Icons.people,
            title: "Profil Pasangan",
            subtitle: "Ubah informasi pasangan",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu Profil Pasangan")));
            },
          ),
          const SizedBox(height: 12),

          // Notifikasi
          _buildSettingCard(
            icon: Icons.notifications,
            title: "Notifikasi",
            subtitle: "Aktifkan / matikan notifikasi transaksi",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu Notifikasi")));
            },
          ),
          const SizedBox(height: 12),

          // Keamanan
          _buildSettingCard(
            icon: Icons.lock,
            title: "Keamanan",
            subtitle: "Atur PIN atau biometrik",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu Keamanan")));
            },
          ),
          const SizedBox(height: 12),

          // Tema
          _buildSettingCard(
            icon: Icons.color_lens,
            title: "Tampilan",
            subtitle: "Ganti tema aplikasi",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu Tampilan")));
            },
          ),
          const SizedBox(height: 20),

          // Logout
          _buildSettingCard(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Keluar dari akun",
            onTap: () async {
              // Jika pakai SharedPreferences, hapus data user di sini
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.clear();

              // Kembali ke halaman LoginPage
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF48668), size: 28),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
