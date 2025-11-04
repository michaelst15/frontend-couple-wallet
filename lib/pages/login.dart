import 'dart:convert';
import 'dart:ui';
import 'package:couple_wallet/pages/controller/fullDataController.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:couple_wallet/main.dart';
import 'package:couple_wallet/pages/register.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FullDataController fullDataController = Get.put(FullDataController());

  bool _isObscure = true;
  bool _isLoading = false;

  /// Fungsi utama login
Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  final String identifier = _emailController.text.trim();
  final String password = _passwordController.text.trim();

  setState(() => _isLoading = true);
  print("🚀 Mulai login dengan email: $identifier");

  try {
    await fullDataController.loadFullData(identifier, password);

    final data = fullDataController.fullData.value;
    print("✅ Data login: $data");

    final msg = (data['message'] ?? '').toString().toLowerCase();
    if (data.isEmpty || !msg.contains('berhasil') || data['user_id'] == null) {
      _showLoginDialog(false, data['message'] ?? "Login gagal 😢", "");
      return;
    }

    final String userName = data['user_name'] ?? "User";
    _showLoginDialog(true, "Login berhasil", userName);

    // ✅ Simpan data untuk navigasi
    final safeData = Map<String, dynamic>.from(data);
    safeData['password'] = password;

    // ✅ Pastikan navigasi dilakukan hanya sekali
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen ?? false) Get.back();

      print("➡️ Navigasi ke MainPage...");
      Get.off(() => MainPage(
            userId: safeData['user_id'],
            userName: safeData['user_name'],
            email: safeData['email'],
            roomId: safeData['room_id'],
            fullData: safeData,
            members: (safeData['members'] as List?) ?? [],
            loginTime: safeData['time']?.toString(),
            pemasukanHarian: [], // sementara kosong
            pengeluaranHarian: [], // sementara kosong
      ));
    });
  } catch (e) {
    print("Error saat login: $e");
    _showLoginDialog(false, "Cek kembali akun anda", "");
  } finally {
    setState(() => _isLoading = false);
  }
}



  /// Popup login sukses/gagal
void _showLoginDialog(bool isSuccess, String message, String userName) {
  if (Get.isDialogOpen ?? false) Get.back();

  showGeneralDialog(
    context: Get.context!,
    barrierDismissible: false,
    barrierLabel: "Login Popup",
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      // ⏱️ Tutup otomatis setelah 3 detik
      Future.delayed(const Duration(seconds: 3), () {
        if (Get.isDialogOpen ?? false) Get.back();
      });

      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: Stack(
          children: [
            // 🔹 Blur background di belakang dialog
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // 🔹 Konten utama popup
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.transparent, // tanpa background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Animasi sukses/gagal (jalan sekali)
                    Lottie.asset(
                      isSuccess
                          ? 'lib/animasi/happy.json'
                          : 'lib/animasi/failed.json',
                      width: 100,
                      height: 100,
                      repeat: false,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 12),

                    // 🔹 Pesan utama
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(1, 1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),

                    // 🔹 Nama user (jika ada)
                    if (userName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(1, 1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEE9E1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('lib/image/logo_couple_wallet.png',
                    width: 100, height: 100),
                const SizedBox(height: 16),
                Text('Couple Wallet',
                    style: GoogleFonts.poppins(
                        color: Colors.deepOrangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 24)),
                Text('Masuk',
                    style: GoogleFonts.poppins(
                        color: Colors.deepOrangeAccent,
                        fontWeight: FontWeight.normal,
                        fontSize: 24)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email atau Username",
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const UnderlineInputBorder(),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFFF48668), width: 2),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? "Email/Nama wajib diisi"
                                : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFFF48668),
                            ),
                            onPressed: () =>
                                setState(() => _isObscure = !_isObscure),
                          ),
                          border: const UnderlineInputBorder(),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFFF48668), width: 2),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? "Password wajib diisi"
                                : null,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF48668),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Masuk Bersama",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Get.off(() => const RegisterPage()),
                          child: Text(
                            "Belum punya akun? Daftar dulu ya",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFF48668),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
