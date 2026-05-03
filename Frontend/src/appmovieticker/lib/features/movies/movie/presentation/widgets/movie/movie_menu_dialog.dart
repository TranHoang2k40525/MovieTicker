import 'package:flutter/material.dart';

import 'package:appmovieticker/core/di/injection_container.dart' as di;
import 'package:appmovieticker/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:appmovieticker/features/auth/presentation/pages/login_page.dart';
import 'package:appmovieticker/features/auth/presentation/pages/register_page.dart';
import 'package:appmovieticker/features/movies/booking/presentation/pages/booking/cinema_booking_list_page.dart';
import 'package:appmovieticker/features/movies/cinema/presentation/pages/cinema/nearby_cinemas_page.dart';
import 'package:appmovieticker/features/movies/booking/presentation/pages/booking/my_tickets_page.dart';
import 'package:appmovieticker/features/movies/notifier/presentation/pages/notification/notifications_page.dart';
import 'package:appmovieticker/features/movies/product/presentation/pages/product/store_catalog_page.dart';
import 'package:appmovieticker/features/movies/booking/presentation/pages/booking/movie_booking_list_page.dart';

Future<void> showMovieMenuDialog(
  BuildContext context, {
  required double scale,
}) async {
  final local = di.sl<AuthLocalDataSource>();
  final token = await local.getToken();
  final profile = await local.getUserProfile();
  if (!context.mounted) return;

  final screenSize = MediaQuery.sizeOf(context);
  final menuWidth = screenSize.width * 0.7;
  final isLoggedIn = token != null && token.isNotEmpty;
  final displayName = (profile?['fullName']?.toString().trim().isNotEmpty ?? false)
      ? profile!['fullName'].toString().trim()
      : 'Thành viên 67CS';
  final memberId = profile?['id']?.toString() ?? '000001';
  final avatarUrl =
      (profile?['avatarUrl'] ?? profile?['avatar'] ?? profile?['imageUrl'])?.toString().trim();
  final hasAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty;
  final safeAvatarUrl = avatarUrl ?? '';
  const guestAvatar = 'assets/images/avatramacdinh.png';
  const memberFallbackAvatar = 'assets/images/—Pngtree—coming soon movie in cinema_1157635.png';
  final fallbackAvatar = isLoggedIn ? memberFallbackAvatar : guestAvatar;

  await showGeneralDialog<void>(
    context: context,
    barrierLabel: 'menu',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: menuWidth,
            padding: EdgeInsets.fromLTRB(12 * scale, 28 * scale, 12 * scale, 12 * scale),
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(22 * scale),
              border: Border.all(color: const Color(0x66FFFFFF)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 70 * scale,
                      height: 70 * scale,
                      child: ClipOval(
                        child: hasAvatarUrl
                            ? Image.network(
                                safeAvatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Image.asset(fallbackAvatar, fit: BoxFit.cover),
                              )
                            : Image.asset(fallbackAvatar, fit: BoxFit.cover),
                      ),
                    ),
                    if (isLoggedIn) ...[
                      SizedBox(width: 8 * scale),
                      InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34 * scale,
                          height: 34 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0x30FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x66FFFFFF)),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8 * scale),
                if (isLoggedIn) ...[
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15 * scale, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8 * scale),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6 * scale),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x55FFFFFF)),
                        bottom: BorderSide(color: Color(0x55FFFFFF)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ID : $memberId',
                          style: TextStyle(color: Colors.white, fontSize: 14 * scale, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          'Tổng chi tiêu 2026 0 đ',
                          style: TextStyle(
                            color: const Color(0xFFFFD460),
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 4 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuTextButton(
                          label: 'Đăng nhập',
                          scale: scale,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                          },
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: _MenuTextButton(
                          label: 'Đăng ký',
                          scale: scale,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTextButton(
                        label: 'Đặt vé theo phim',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MovieBookingListPage()),
                          );
                        },
                      ),
                    ),
                    Container(width: 1, height: 20 * scale, color: const Color(0x55FFFFFF)),
                    Expanded(
                      child: _MenuTextButton(
                        label: 'Đặt vé theo rạp',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CinemaBookingListPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12 * scale),
                Expanded(
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10 * scale,
                    crossAxisSpacing: 8 * scale,
                    childAspectRatio: 0.88,
                    children: [
                      _MenuIconItem(
                        icon: Icons.home_outlined,
                        label: 'Trang chủ',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                      ),
                      _MenuIconItem(
                        icon: Icons.person_outline,
                        label: 'Thành viên',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          if (!isLoggedIn) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                          }
                        },
                      ),
                      _MenuIconItem(
                        icon: Icons.info_outline,
                        label: 'Rạp',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NearbyCinemasPage()),
                          );
                        },
                      ),
                      _MenuIconItem(icon: Icons.card_giftcard_outlined, label: 'Ưu đãi', scale: scale, onTap: () => Navigator.of(dialogContext).pop()),
                      _MenuIconItem(
                        icon: Icons.confirmation_num_outlined,
                        label: 'Vé của tôi',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          if (!isLoggedIn) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyTicketsPage()),
                          );
                        },
                      ),
                      _MenuIconItem(icon: Icons.redeem_outlined, label: 'Đổi ưu đãi', scale: scale, onTap: () => Navigator.of(dialogContext).pop()),
                      _MenuIconItem(
                        icon: Icons.store_outlined,
                        label: 'Store',
                        scale: scale,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StoreCatalogPage()),
                          );
                        },
                      ),
                      const SizedBox.shrink(),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                SizedBox(height: 8 * scale),
                if (isLoggedIn)
                  _MenuTextButton(
                    label: 'Đăng xuất',
                    scale: scale,
                    onTap: () async {
                      await local.clearToken();
                      if (context.mounted) Navigator.of(dialogContext).pop();
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MenuTextButton extends StatelessWidget {
  const _MenuTextButton({
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 8 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10 * scale),
          side: const BorderSide(color: Color(0x55FFFFFF)),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13 * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuIconItem extends StatelessWidget {
  const _MenuIconItem({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40 * scale,
            height: 40 * scale,
            decoration: BoxDecoration(
              color: const Color(0x30FFFFFF),
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(color: const Color(0x55FFFFFF)),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20 * scale,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
