import 'package:flutter/material.dart';

/// Staggered fade + slide animation for list items
class AnimatedListWrapper extends StatelessWidget {
  const AnimatedListWrapper({
    super.key,
    required this.child,
    required this.index,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0, 0.15),
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  @override
  Widget build(BuildContext context) {
    return _AnimatedListItem(
      index: index,
      delay: delay,
      duration: duration,
      slideOffset: slideOffset,
      child: child,
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  const _AnimatedListItem({
    required this.child,
    required this.index,
    required this.delay,
    required this.duration,
    required this.slideOffset,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final staggerDelay = Duration(milliseconds: widget.index * 60);
    final totalDelay = widget.delay + staggerDelay;

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(totalDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Implicitly animated card that scales on hover/press
class AnimatedScaleCard extends StatefulWidget {
  const AnimatedScaleCard({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<AnimatedScaleCard> createState() => _AnimatedScaleCardState();
}

class _AnimatedScaleCardState extends State<AnimatedScaleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse();
  void _onTapUp(TapUpDetails _) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Hero-style container animation for smooth page-to-page transitions
class AnimatedHeroContainer extends StatelessWidget {
  const AnimatedHeroContainer({
    super.key,
    required this.child,
    required this.tag,
    this.borderRadius,
  });

  final Widget child;
  final String tag;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.lerp(
                  borderRadius ?? BorderRadius.circular(12),
                  borderRadius ?? BorderRadius.circular(12),
                  animation.value,
                ),
              ),
              child: child,
            );
          },
          child: child,
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
    )..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor ?? Colors.grey.shade300,
                widget.highlightColor ?? Colors.grey.shade100,
                widget.baseColor ?? Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlideGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.percent);
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}

/// Page transition animation wrapper
class PageTransitionWrapper extends StatelessWidget {
  const PageTransitionWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
