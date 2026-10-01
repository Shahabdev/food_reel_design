import 'package:flutter/material.dart';
import '../animations/spring_curve.dart';
import 'animated_digit_text.dart';

class AnimatedCartBar extends StatefulWidget {
  final int totalCount;
  final double totalPrice;
  final VoidCallback onTap;
  final GlobalKey? orangeBagKey;

  const AnimatedCartBar({
    super.key,
    required this.totalCount,
    required this.totalPrice,
    required this.onTap,
    this.orangeBagKey,
  });

  @override
  State<AnimatedCartBar> createState() => AnimatedCartBarState();
}

class AnimatedCartBarState extends State<AnimatedCartBar>
    with TickerProviderStateMixin {
  // Gentle slow hover floating movement
  late AnimationController _hoverController;
  late Animation<double> _hoverAnim;

  // Catch pulse animation on orange button when item is added
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _bagRotation;
  late Animation<double> _glowRadius;

  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.totalCount;

    // 1. Subtle slow floating hover (4.2s gentle wave)
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _hoverAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOutSine),
    );

    // 2. Slow catch pulse animation (800ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutCubic,
      ),
    );

    _bagRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowRadius = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 24.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 24.0, end: 12.0), weight: 2),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant AnimatedCartBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalCount > _previousCount) {
      triggerPulse();
    }
    _previousCount = widget.totalCount;
  }

  void triggerPulse() {
    _pulseController.reset();
    _pulseController.forward();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = widget.totalCount > 0;

    return AnimatedBuilder(
      animation: Listenable.merge([_hoverAnim, _pulseController]),
      builder: (context, _) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 900),
          curve: const SpringOvershootCurve(),
          offset: isVisible ? Offset.zero : const Offset(0, 1.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isVisible ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 900),
              curve: const SpringOvershootCurve(),
              scale: isVisible ? 1.0 : 0.94,
              child: Transform.translate(
                offset: Offset(0, isVisible ? _hoverAnim.value : 0),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    height: 66,
                    decoration: const BoxDecoration(
                      color: Color(0xFF18181A),
                      borderRadius: BorderRadius.all(Radius.circular(36)),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.32),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 6, 8, 6),
                    child: Row(
                      children: [
                        // "X Item Selected" with slow animated rolling number
                        Expanded(
                          child: Row(
                            children: [
                              AnimatedSlideText(
                                text: '${widget.totalCount}',
                                duration: const Duration(milliseconds: 600),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.totalCount == 1
                                    ? 'Item Selected'
                                    : 'Items Selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Price with slow animated number transitions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              r'$ ',
                              style: TextStyle(
                                color: Color(0xFFFF6B4A),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AnimatedSlideText(
                              text: widget.totalPrice.toStringAsFixed(2),
                              duration: const Duration(milliseconds: 600),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        // Orange Shopping Bag Button with slow pulse, bounce, and glow
                        Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            key: widget.orangeBagKey,
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B4A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B4A)
                                      .withValues(alpha: 0.55),
                                  blurRadius: _glowRadius.value,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: _bagRotation.value,
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
