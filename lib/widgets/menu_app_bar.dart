import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

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
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(MainAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNewData && !_shakeController.isAnimating) {
      _shakeController.repeat(reverse: true);
    } else if (!widget.hasNewData && _shakeController.isAnimating) {
      _shakeController.stop();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _showNotificationPopup() {
    if (widget.newDataList == null || widget.newDataList!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return FadeInDown(
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "🔔 Data Baru Tersedia",
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
                    subtitle:
                        Text(data['description'] ?? 'Update terbaru diterima'),
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
      actions: [
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final offset = 2 * (1 - (_shakeController.value * 2 - 1).abs());
            return Transform.translate(
              offset: widget.hasNewData ? Offset(offset, 0) : Offset.zero,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: _showNotificationPopup,
                    tooltip: 'Lihat Notifikasi',
                  ),
                  if (widget.hasNewData)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
