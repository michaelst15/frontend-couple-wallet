import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onRefresh;
  final GlobalKey<ScaffoldState> scaffoldKey;

  // 🔔 tambahan parameter untuk notifikasi
  final bool hasNewData;
  final List<Map<String, dynamic>>? newDataList;
  final VoidCallback? onClearNotification;

  const MainAppBar({
    super.key,
    required this.title,
    required this.scaffoldKey,
    this.onRefresh,
    this.hasNewData = false,
    this.newDataList,
    this.onClearNotification,
  });

  @override
  State<MainAppBar> createState() => _MainAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MainAppBarState extends State<MainAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(MainAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🌀 Saat data baru muncul → mainkan animasi
    if (widget.hasNewData) {
      _lottieController.repeat(); // Loop animasi selama ada data baru
    } else {
      _lottieController.stop();
      _lottieController.reset(); // Diam di frame awal
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _showNotificationPopup() {
    if (widget.newDataList == null || widget.newDataList!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return FadeInDown(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Data Baru Tersedia",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.newDataList!.length,
                itemBuilder: (context, index) {
                  final data = widget.newDataList![index];
                  return ListTile(
                    leading: const Icon(Icons.fiber_new, color: Colors.orange),
                    title: Text(data['title'] ?? 'Data baru'),
                    subtitle: Text(data['description'] ?? 'Update terbaru diterima'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  widget.onClearNotification?.call();
                  Navigator.pop(context);
                },
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF48668),
      elevation: 0,
      title: Text(
        widget.title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      // leading: IconButton(
      //   icon: const Icon(Icons.menu, color: Colors.white),
      //   onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
      // ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: _showNotificationPopup,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ⚪ Background putih bulat lebih kecil & center
                Container(
                  width: 44, // sedikit lebih kecil dari sebelumnya
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    // 🔔 Perbesar sedikit animasi di dalam lingkaran
                    child: Transform.scale(
                      scale: 1.15, // sesuaikan proporsi animasi di dalam background
                      child: Lottie.asset(
                        'lib/animasi/notifikasi.json',
                        controller: _lottieController,
                        repeat: true,
                        animate: widget.hasNewData,
                        onLoaded: (composition) {
                          _lottieController.duration = composition.duration;
                          if (widget.hasNewData) {
                            _lottieController.repeat();
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // 🔴 Titik merah indikator notifikasi baru
                if (widget.hasNewData)
                  Positioned(
                    right: 8,
                    top: 6,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            )




          ),
        ),
      ],
    );
  }
}
