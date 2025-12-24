import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/theme/web_theme.dart';
import 'package:tindart/utils/breakpoints.dart';
import 'package:tindart/web/widgets/web_header.dart';

class WebHomeScreen extends StatelessWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isMobile = deviceType == DeviceType.mobile;

    return Scaffold(
      backgroundColor: WebColors.background,
      body: Column(
        children: [
          const WebHeader(currentRoute: '/'),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 24 : 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TINDART',
                      style: TextStyle(
                        fontSize: isMobile ? 48 : 72,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 8,
                        color: WebColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Swipe to find art you love.',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w300,
                        color: WebColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _EnterButton(
                      onTap: () => context.go('/gallery'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Discover and curate your personal art collection',
              style: TextStyle(
                fontSize: 14,
                color: WebColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterButton extends StatefulWidget {
  final VoidCallback onTap;

  const _EnterButton({required this.onTap});

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? WebColors.textPrimary : Colors.transparent,
            border: Border.all(
              color: WebColors.textPrimary,
              width: 1,
            ),
          ),
          child: Text(
            'ENTER GALLERY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
              color: _isHovered ? WebColors.surface : WebColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
