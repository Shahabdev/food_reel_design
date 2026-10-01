import 'package:flutter/material.dart';
import '../animations/spring_curve.dart';

class AnimatedHeaderSection extends StatefulWidget {
  final Animation<double> entranceProgress;
  final int totalItemCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;
  final VoidCallback? onLocationTap;
  final GlobalKey? topCartKey;

  const AnimatedHeaderSection({
    super.key,
    required this.entranceProgress,
    required this.totalItemCount,
    required this.onNotificationTap,
    required this.onCartTap,
    this.onLocationTap,
    this.topCartKey,
  });

  @override
  State<AnimatedHeaderSection> createState() => _AnimatedHeaderSectionState();
}

class _AnimatedHeaderSectionState extends State<AnimatedHeaderSection>
    with TickerProviderStateMixin {
  // Continuous micro-float for location
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  // Bell shake once on entrance
  late AnimationController _bellShakeController;
  late Animation<double> _bellShakeAnim;

  // Notification badge pulse on load
  late AnimationController _badgePulseController;
  late Animation<double> _badgePulseAnim;

  // Arrow tap bounce
  late AnimationController _arrowBounceController;
  late Animation<double> _arrowBounceAnim;

  int _previousCount = 0;
  bool _cartBumped = false;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.totalItemCount;

    // 1. Subtle location float (gentle 4.8s breathing)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Bell shake controller (slow, visible shake)
    _bellShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bellShakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _bellShakeController, curve: Curves.easeInOut),
    );

    // 3. Badge pulse on initial load (slow gentle pulse)
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _badgePulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeInOut),
    );

    // 4. Arrow tap bounce
    _arrowBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _arrowBounceAnim = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _arrowBounceController,
        curve: const SpringOvershootCurve(),
      ),
    );

    // Trigger bell shake and badge pulse when entrance reaches ~0.2
    widget.entranceProgress.addListener(_handleEntranceForMicro);
  }

  void _handleEntranceForMicro() {
    if (widget.entranceProgress.value > 0.15 &&
        !_bellShakeController.isAnimating &&
        _bellShakeController.value == 0.0) {
      _bellShakeController.forward();
      _badgePulseController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedHeaderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalItemCount != _previousCount) {
      _previousCount = widget.totalItemCount;
      setState(() {
        _cartBumped = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _cartBumped = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget.entranceProgress.removeListener(_handleEntranceForMicro);
    _floatController.dispose();
    _bellShakeController.dispose();
    _badgePulseController.dispose();
    _arrowBounceController.dispose();
    super.dispose();
  }

  void _onArrowTapped() {
    _arrowBounceController.forward().then((_) {
      _arrowBounceController.reverse();
    });
    widget.onLocationTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.entranceProgress,
        _floatAnim,
        _bellShakeAnim,
        _badgePulseAnim,
        _arrowBounceAnim,
      ]),
      builder: (context, child) {
        // Header Top Row Entrance: 0.05 -> 0.35
        final headerInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: const Interval(0.05, 0.35, curve: Curves.easeOutCubic),
        );
        final headerOpacity = headerInterval.value;
        final headerSlideY = (1.0 - headerInterval.value) * -20.0;

        // Headline "Hungry?" entrance: 0.15 -> 0.40
        final hungryInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: const Interval(0.15, 0.40, curve: Curves.easeOutCubic),
        );
        final hungryOpacity = hungryInterval.value;
        final hungrySlideX = (1.0 - hungryInterval.value) * -16.0;

        // Headline "Order & Eat." entrance: 0.25 -> 0.50
        final orderInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: const Interval(0.25, 0.50, curve: Curves.easeOutCubic),
        );
        final orderOpacity = orderInterval.value;
        final orderSlideX = (1.0 - orderInterval.value) * 16.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation Row
              Transform.translate(
                offset: Offset(0, headerSlideY),
                child: Opacity(
                  opacity: headerOpacity.clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Delivery to Address with Truck Icon & subtle float
                      GestureDetector(
                        onTap: _onArrowTapped,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFECEEF2),
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.02),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: Color(0xFF1E2124),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery to',
                                  style: TextStyle(
                                    color: Color(0xFF8F959E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Text(
                                      '11/2 Diriyah, Riyadh',
                                      style: TextStyle(
                                        color: Color(0xFF18181A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Transform.translate(
                                      offset: Offset(0, _arrowBounceAnim.value),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: Color(0xFF18181A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right: Notification Bell & Cart Badge
                      Row(
                        children: [
                          // Bell button with entrance shake & pulsing badge
                          GestureDetector(
                            onTap: widget.onNotificationTap,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFECEEF2),
                                      width: 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.02),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Transform.rotate(
                                    angle: _bellShakeAnim.value,
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Color(0xFF1E2124),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Transform.scale(
                                    scale: _badgePulseAnim.value,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6B4A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Shopping bag button with scale bump on cart change
                          GestureDetector(
                            key: widget.topCartKey,
                            onTap: widget.onCartTap,
                            child: AnimatedScale(
                              scale: _cartBumped ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFECEEF2),
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color.fromRGBO(0, 0, 0, 0.02),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Color(0xFF1E2124),
                                      size: 20,
                                    ),
                                  ),
                                  if (widget.totalItemCount > 0)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration:
                                            const Duration(milliseconds: 600),
                                        curve: Curves.elasticOut,
                                        builder: (context, scaleVal, _) {
                                          return Transform.scale(
                                            scale: scaleVal,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF6B4A),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${widget.totalItemCount}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Hero Title: "Hungry? Order & Eat."
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // "Hungry?" reveals first
                  Transform.translate(
                    offset: Offset(hungrySlideX, 0),
                    child: Opacity(
                      opacity: hungryOpacity.clamp(0.0, 1.0),
                      child: const Text(
                        'Hungry? ',
                        style: TextStyle(
                          color: Color(0xFF18181A),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),

                  // "Order & Eat." reveals right after with smooth horizontal slide
                  Transform.translate(
                    offset: Offset(orderSlideX, 0),
                    child: Opacity(
                      opacity: orderOpacity.clamp(0.0, 1.0),
                      child: const Text(
                        'Order & Eat.',
                        style: TextStyle(
                          color: Color(0xFF9EA3AE),
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
