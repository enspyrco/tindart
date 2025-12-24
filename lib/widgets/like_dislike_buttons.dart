import 'package:flutter/material.dart';
import 'package:tindart/theme/web_theme.dart';

class LikeDislikeButtons extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final bool large;

  const LikeDislikeButtons({
    super.key,
    this.isLiked = false,
    this.onLike,
    this.onDislike,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = large ? 32.0 : 24.0;
    final buttonSize = large ? 64.0 : 48.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.close,
          color: WebColors.disliked,
          size: buttonSize,
          iconSize: iconSize,
          onTap: onDislike,
          tooltip: 'Skip',
        ),
        SizedBox(width: large ? 24 : 16),
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          color: WebColors.liked,
          size: buttonSize,
          iconSize: iconSize,
          onTap: onLike,
          tooltip: isLiked ? 'Liked' : 'Like',
          filled: isLiked,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final String tooltip;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    this.onTap,
    required this.tooltip,
    this.filled = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.filled
                  ? widget.color
                  : (_isHovered
                      ? widget.color.withValues(alpha: 0.1)
                      : Colors.transparent),
              border: Border.all(
                color: widget.color,
                width: 2,
              ),
            ),
            child: Icon(
              widget.icon,
              color: widget.filled ? Colors.white : widget.color,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
