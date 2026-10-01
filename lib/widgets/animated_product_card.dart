import 'package:flutter/material.dart';
import '../animations/spring_curve.dart';
import '../models/food_item.dart';

class AnimatedProductCard extends StatefulWidget {
  final FoodItem item;
  final bool isInCart;
  final int quantity;
  final int index;
  final Animation<double> entranceProgress;
  final Animation<double> floatingAnimation;
  final double scrollOffset;
  final VoidCallback onTap;
  final void Function(Offset globalImagePos, Size imageSize) onAdd;
  final VoidCallback onRemove;

  const AnimatedProductCard({
    super.key,
    required this.item,
    required this.isInCart,
    required this.quantity,
    required this.index,
    required this.entranceProgress,
    required this.floatingAnimation,
    required this.scrollOffset,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _imageKey = GlobalKey();

  // Button tap spring scale controller
  late AnimationController _btnAnimController;
  late Animation<double> _btnScale;

  // Card feedback pulse on add
  double _cardPulseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _btnAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _btnScale = Tween<double>(begin: 1.0, end: 0.84).animate(
      CurvedAnimation(
        parent: _btnAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _btnAnimController.dispose();
    super.dispose();
  }

  void _handleButtonTap() {
    _btnAnimController.forward().then((_) {
      _btnAnimController.reverse();
    });

    if (widget.isInCart) {
      widget.onRemove();
    } else {
      // Find global position of the food image for the curved fly-to-cart animation
      Offset startPos = Offset.zero;
      Size imgSize = const Size(70, 70);

      final renderBox =
          _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        startPos = renderBox.localToGlobal(Offset.zero);
        imgSize = renderBox.size;
      }

      // Card micro-pulse feedback
      setState(() {
        _cardPulseScale = 1.025;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _cardPulseScale = 1.0;
          });
        }
      });

      widget.onAdd(startPos, imgSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Staggered timing per card
    final double start = (0.50 + widget.index * 0.07).clamp(0.0, 0.88);
    final double end = (start + 0.22).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.entranceProgress,
        widget.floatingAnimation,
        _btnAnimController,
      ]),
      builder: (context, child) {
        final cardInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        // Opacity: 0 -> 1
        final double opacity = cardInterval.value.clamp(0.0, 1.0);
        // Translation Y: 30 -> 0
        final double translateY = (1.0 - cardInterval.value) * 30.0;
        // Scale: 0.96 -> 1.0
        final double entranceScale = 0.96 + 0.04 * cardInterval.value;

        // Discount badge pop-in with spring
        final badgeInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: Interval(
            (start + 0.08).clamp(0.0, 0.92),
            (start + 0.22).clamp(0.0, 1.0),
            curve: const GentleBounceCurve(),
          ),
        );
        final double badgeScale = badgeInterval.value.clamp(0.0, 1.15);

        // Parallax + floating calculation for food photo
        final floatOffset = (widget.index % 2 == 0)
            ? widget.floatingAnimation.value
            : -widget.floatingAnimation.value;
        final parallaxOffset = -(widget.scrollOffset * 0.04).clamp(-12.0, 12.0);

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: entranceScale * _cardPulseScale,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. The White Card Container with rounded corners and drop shadow
                    Positioned(
                      top: 39,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 58),

                            // Black Discount Badge with Spring Pop-In
                            Transform.scale(
                              scale: badgeScale,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.item.discount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Item Title
                            Text(
                              widget.item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF18181A),
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // Item Subtitle
                            Text(
                              widget.item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF989EAB),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const Spacer(),

                            // Price and Action Button (+ or -)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Price
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    const Text(
                                      r'$ ',
                                      style: TextStyle(
                                        color: Color(0xFFFF6B4A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      widget.item.price.toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Color(0xFF18181A),
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),

                                // Interactive Spring Button
                                GestureDetector(
                                  onTap: _handleButtonTap,
                                  child: Transform.scale(
                                    scale: _btnScale.value,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 450),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: widget.isInCart
                                            ? const Color(0xFF18181A)
                                            : const Color(0xFFF7F8FA),
                                        shape: BoxShape.circle,
                                        boxShadow: widget.isInCart
                                            ? const [
                                                BoxShadow(
                                                  color: Color.fromRGBO(
                                                    24,
                                                    24,
                                                    26,
                                                    0.25,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ]
                                            : const [],
                                      ),
                                      child: Center(
                                        child: AnimatedRotation(
                                          turns: widget.isInCart ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 450,
                                          ),
                                          child: Icon(
                                            widget.isInCart
                                                ? Icons.remove_rounded
                                                : Icons.add_rounded,
                                            color: widget.isInCart
                                                ? Colors.white
                                                : const Color(0xFF18181A),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Floating Animated Food Photo with Parallax
                    Positioned(
                      top: 0,
                      left: 8,
                      right: 8,
                      height: 98,
                      child: Transform.translate(
                        offset: Offset(0, floatOffset + parallaxOffset),
                        child: Center(
                          key: _imageKey,
                          child: Image.asset(
                            widget.item.imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.fastfood_rounded,
                                size: 64,
                                color: Color(0xFF18181A),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
