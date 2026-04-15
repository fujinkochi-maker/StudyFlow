import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SuccessRipple extends StatefulWidget {
  const SuccessRipple({
    super.key,
    this.size = 80,
    this.color,
    this.onComplete,
  });

  final double size;
  final Color? color;
  final VoidCallback? onComplete;

  @override
  State<SuccessRipple> createState() => _SuccessRippleState();
}

class _SuccessRippleState extends State<SuccessRipple>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _scaleController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _rippleController.forward();
    _scaleController.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * (1 + _rippleAnimation.value),
                height: widget.size * (1 + _rippleAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.3 * (1 - _rippleAnimation.value)),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size * (0.7 + _rippleAnimation.value * 0.5),
                height: widget.size * (0.7 + _rippleAnimation.value * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2 * (1 - _rippleAnimation.value)),
                ),
              );
            },
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.check(),
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
