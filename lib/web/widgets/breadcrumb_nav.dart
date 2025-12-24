import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/theme/web_theme.dart';

class BreadcrumbItem {
  final String label;
  final String? route;

  const BreadcrumbItem({
    required this.label,
    this.route,
  });
}

class BreadcrumbNav extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbNav({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontSize: 14,
                      color: WebColors.textSecondary,
                    ),
                  ),
                ),
              Flexible(
                child: _BreadcrumbLink(
                  item: items[i],
                  isLast: i == items.length - 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbLink extends StatefulWidget {
  final BreadcrumbItem item;
  final bool isLast;

  const _BreadcrumbLink({
    required this.item,
    this.isLast = false,
  });

  @override
  State<_BreadcrumbLink> createState() => _BreadcrumbLinkState();
}

class _BreadcrumbLinkState extends State<_BreadcrumbLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.item.route != null && !widget.isLast;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isClickable ? () => context.go(widget.item.route!) : null,
        child: Text(
          widget.item.label,
          style: TextStyle(
            fontSize: 14,
            color: widget.isLast
                ? WebColors.textPrimary
                : (_isHovered ? WebColors.textPrimary : WebColors.textSecondary),
            decoration:
                isClickable && _isHovered ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
