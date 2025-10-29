import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../pages/controller/fullDataController.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FullDataController controller = Get.find<FullDataController>();

  String? _selectedRoom;
  bool _isObscure1 = true;
  bool _isObscure2 = true;

  @override
  void initState() {
    super.initState();
    controller.loadRooms(); // 🔹 Ambil data room dari API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEE9E1),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 🌸 Logo + Judul
                    Column(
                      children: [
                        Image.asset('lib/image/logo_couple_wallet.png', width: 100, height: 100),
                        const SizedBox(height: 10),
                        Text("Couple Wallet",
                            style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrangeAccent)),
                        Text("Daftar",
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                color: Colors.deepOrangeAccent,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 💌 Card Input
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: Obx(() {
                        final isLoading = controller.isLoading.value;
                        final rooms = controller.rooms;

                        return Column(
                          children: [
                            // Nama Lengkap
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "Nama Lengkap",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                            ),
                            const SizedBox(height: 20),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: "Email",
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v!.isEmpty) return "Email wajib diisi";
                                if (!v.contains("@")) return "Email tidak valid";
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscure1,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure1 ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFFF48668),
                                  ),
                                  onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                                ),
                              ),
                              validator: (v) => v!.length < 6 ? "Minimal 6 karakter" : null,
                            ),
                            const SizedBox(height: 20),

                            // Konfirmasi Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _isObscure2,
                              decoration: InputDecoration(
                                labelText: "Konfirmasi Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure2 ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFFF48668),
                                  ),
                                  onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                                ),
                              ),
                              validator: (v) => v != _passwordController.text
                                  ? "Password tidak cocok"
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Dropdown Room
                            DropdownButtonFormField<String>(
                              value: _selectedRoom,
                              decoration: const InputDecoration(
                                labelText: "Pilih Room",
                                prefixIcon: Icon(Icons.favorite_outline),
                              ),
                              items: rooms.map<DropdownMenuItem<String>>((room) {
                                final status = room["status"] ?? "unknown";
                                final color = status.toLowerCase() == "max"
                                    ? Colors.red
                                    : Colors.green;
                                return DropdownMenuItem<String>(
                                  value: room["room_name"],
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(room["room_name"]),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                final selected = rooms.firstWhereOrNull(
                                  (r) => r["room_name"] == v,
                                );
                                if (selected != null &&
                                    selected["status"]?.toLowerCase() == "max") {
                                  controller.showPopup(context, "Room sudah penuh", false);
                                  return;
                                }
                                setState(() => _selectedRoom = v);
                              },
                              validator: (v) => v == null ? "Pilih room dulu" : null,
                            ),
                            const SizedBox(height: 30),

                            // Tombol Daftar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          controller.registerUser(
                                            fullName: _nameController.text,
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                            confirmPassword:
                                                _confirmPasswordController.text,
                                            roomName: _selectedRoom!,
                                            context: context,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF48668),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text("Daftar Bersama",
                                        style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Tombol ke Login
                            TextButton(
                              onPressed: () {
                                Get.off(() => const LoginPage());
                              },
                              child: Text("Sudah punya akun? Masuk",
                                  style: GoogleFonts.poppins(
                                      color: const Color(0xFFF48668))),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlay Loading
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black45,
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                )
              : const SizedBox()),
        ],
      ),
    );
  }
}
