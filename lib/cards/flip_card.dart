import 'package:flutter/material.dart';
import 'dart:math';

class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;

    setState(() {
      _isFront = !_isFront;
    });

    if (_isFront) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle =
              _isFront ? _animation.value * pi : (1 - _animation.value) * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: _isFront ? widget.front : widget.back,
          );
        },
      ),
    );
  }
}
