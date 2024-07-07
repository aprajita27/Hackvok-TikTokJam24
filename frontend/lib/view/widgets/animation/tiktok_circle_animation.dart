import 'package:flutter/material.dart';

class TiktokCircleAnimation extends StatefulWidget {
  final Widget child;

  const TiktokCircleAnimation({required this.child});

  @override
  _TiktokCircleAnimationState createState() => _TiktokCircleAnimationState();
}

class _TiktokCircleAnimationState extends State<TiktokCircleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    controller.forward();
    controller.repeat();
  }

  @override
  void dispose() {
    // Dispose of the animation controller
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(controller),
      child: widget.child,
    );
  }
}
