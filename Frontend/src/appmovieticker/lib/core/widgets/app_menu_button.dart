import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../di/injection_container.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    super.key,
    required this.onNavigateTab,
  });

  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu),
      onPressed: () => _openMenu(context),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final local = sl<AuthLocalDataSource>();
    final token = await local.getToken();
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: const AssetImage('assets/images/avatramacdinh.png'),
                        backgroundColor: Colors.white,
                        onBackgroundImageError: (exception, stackTrace) {},
                      ),
                      const SizedBox(height: 10),
                      if (!isLoggedIn) ...[
                        _MenuAction(
                          icon: FontAwesomeIcons.rightToBracket,
                          title: 'Dang nhap',
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                          },
                        ),
                        _MenuAction(
                          icon: FontAwesomeIcons.userPlus,
                          title: 'Dang ky',
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                        ),
                      ] else ...[
                        _MenuAction(
                          icon: FontAwesomeIcons.rightFromBracket,
                          title: 'Dang xuat',
                          onTap: () async {
                            await local.clearToken();
                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                      _MenuAction(
                        icon: FontAwesomeIcons.film,
                        title: 'Dat ve theo phim',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onNavigateTab(1);
                        },
                      ),
                      _MenuAction(
                        icon: FontAwesomeIcons.building,
                        title: 'Dat ve theo rap',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onNavigateTab(1);
                        },
                      ),
                      _MenuGrid(
                        onItemTap: (index) {
                          Navigator.of(dialogContext).pop();
                          onNavigateTab(index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14, color: const Color(0xFF0F172A)),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.onItemTap});

  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _GridItem(icon: FontAwesomeIcons.house, label: 'Trang chu', tabIndex: 0),
      _GridItem(icon: FontAwesomeIcons.ticket, label: 'Dat ve', tabIndex: 1),
      _GridItem(icon: FontAwesomeIcons.receipt, label: 'Ve cua toi', tabIndex: 2),
      _GridItem(icon: FontAwesomeIcons.bell, label: 'Thong bao', tabIndex: 3),
      _GridItem(icon: FontAwesomeIcons.gift, label: 'Uu dai', tabIndex: 4),
      _GridItem(icon: FontAwesomeIcons.tags, label: 'Voucher', tabIndex: 4),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: items
            .map(
              (item) => InkWell(
                onTap: () => onItemTap(item.tabIndex),
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 86,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: FaIcon(item.icon, color: const Color(0xFF0F172A), size: 18),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GridItem {
  const _GridItem({
    required this.icon,
    required this.label,
    required this.tabIndex,
  });

  final IconData icon;
  final String label;
  final int tabIndex;
}
