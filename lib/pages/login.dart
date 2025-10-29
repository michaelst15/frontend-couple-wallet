import 'dart:convert';
import 'package:couple_wallet/pages/controller/fullDataController.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:couple_wallet/main.dart';
import 'package:couple_wallet/pages/register.dart';

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
    _showLoginDialog(true, "Login berhasil 💕", userName);

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
    print("❌ Error saat login: $e");
    _showLoginDialog(false, "Gagal terhubung ke server 😢", "");
  } finally {
    setState(() => _isLoading = false);
  }
}



  /// Popup login sukses/gagal
  void _showLoginDialog(bool isSuccess, String message, String userName) {
    if (Get.isDialogOpen ?? false) Get.back();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Login Popup",
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Center(
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (userName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
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
                                "Masuk Bersama 💑",
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
                            "Belum punya akun? Daftar dulu ya 💕",
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
