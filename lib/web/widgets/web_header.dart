import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/theme/web_theme.dart';
import 'package:tindart/utils/breakpoints.dart';

class WebHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? currentRoute;

  const WebHeader({super.key, this.currentRoute});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isMobile = getDeviceType(context) == DeviceType.mobile;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: WebColors.surface,
        border: Border(
          bottom: BorderSide(color: WebColors.border),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () => context.go('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                'TINDART',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                  color: WebColors.textPrimary,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Navigation
          if (isMobile)
            _MobileMenu(currentRoute: currentRoute)
          else
            _DesktopNav(currentRoute: currentRoute),
        ],
      ),
    );
  }
}

class _DesktopNav extends StatelessWidget {
  final String? currentRoute;

  const _DesktopNav({this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavLink(
          label: 'Gallery',
          route: '/gallery',
          isActive: currentRoute == '/gallery',
        ),
        const SizedBox(width: 32),
        _NavLink(
          label: 'Liked',
          route: '/liked',
          isActive: currentRoute == '/liked',
        ),
        const SizedBox(width: 32),
        _NavLink(
          label: 'Profile',
          route: '/profile',
          isActive: currentRoute == '/profile',
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final String route;
  final bool isActive;

  const _NavLink({
    required this.label,
    required this.route,
    this.isActive = false,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive || _isHovered
                    ? WebColors.textPrimary
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.w400,
              color: WebColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  final String? currentRoute;

  const _MobileMenu({this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: WebColors.textPrimary),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: WebColors.border),
      ),
      onSelected: (route) => context.go(route),
      itemBuilder: (context) => [
        _buildMenuItem('Gallery', '/gallery', currentRoute == '/gallery'),
        _buildMenuItem('Liked', '/liked', currentRoute == '/liked'),
        _buildMenuItem('Profile', '/profile', currentRoute == '/profile'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String label, String route, bool isActive) {
    return PopupMenuItem<String>(
      value: route,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          color: WebColors.textPrimary,
        ),
      ),
    );
  }
}
