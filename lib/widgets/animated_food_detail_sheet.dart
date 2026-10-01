import 'package:flutter/material.dart';
import '../animations/spring_curve.dart';
import '../models/food_item.dart';
import 'animated_digit_text.dart';

class AnimatedFoodDetailSheet extends StatefulWidget {
  final FoodItem item;
  final int initialQuantity;
  final void Function(int newQty) onQuantityChanged;
  final VoidCallback onAddToCart;

  const AnimatedFoodDetailSheet({
    super.key,
    required this.item,
    required this.initialQuantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  static Future<void> show(
    BuildContext context, {
    required FoodItem item,
    required int initialQuantity,
    required void Function(int newQty) onQuantityChanged,
    required VoidCallback onAddToCart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return AnimatedFoodDetailSheet(
          item: item,
          initialQuantity: initialQuantity,
          onQuantityChanged: onQuantityChanged,
          onAddToCart: onAddToCart,
        );
      },
    );
  }

  @override
  State<AnimatedFoodDetailSheet> createState() =>
      _AnimatedFoodDetailSheetState();
}

class _AnimatedFoodDetailSheetState extends State<AnimatedFoodDetailSheet>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  // Button tap spring scale
  late AnimationController _btnScaleController;
  late Animation<double> _btnScale;

  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;

    // 1. Entrance animation (slow cinematic 900ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // 2. Subtle floating food photo (gentle 3.6s oscillation)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 3. Button press spring controller
    _btnScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _btnScaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _btnScaleController.dispose();
    super.dispose();
  }

  void _handleAddToCartTap() {
    _btnScaleController.forward().then((_) {
      _btnScaleController.reverse();
    });

    if (_quantity == 0) {
      setState(() {
        _quantity = 1;
      });
      widget.onQuantityChanged(1);
    }
    widget.onAddToCart();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveQty = _quantity > 0 ? _quantity : 1;
    final totalPrice = widget.item.price * effectiveQty;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _floatAnim,
        _btnScaleController,
      ]),
      builder: (context, _) {
        // Image entrance: 0.05 -> 0.55 with scale and fade
        final imageInterval = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.05, 0.55, curve: Curves.easeOutBack),
        );
        final imageScale = 0.75 + 0.25 * imageInterval.value;
        final imageOpacity = imageInterval.value.clamp(0.0, 1.0);

        // Title & badge: 0.20 -> 0.60
        final titleInterval = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.20, 0.60, curve: Curves.easeOutCubic),
        );
        final titleSlideY = (1.0 - titleInterval.value) * 20.0;
        final titleOpacity = titleInterval.value.clamp(0.0, 1.0);

        // Discount badge spring pop-in: 0.30 -> 0.70
        final badgeInterval = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.30, 0.70, curve: GentleBounceCurve()),
        );
        final badgeScale = badgeInterval.value.clamp(0.0, 1.15);

        // Subtitle: 0.28 -> 0.65
        final subInterval = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.28, 0.65, curve: Curves.easeOutCubic),
        );
        final subSlideY = (1.0 - subInterval.value) * 16.0;
        final subOpacity = subInterval.value.clamp(0.0, 1.0);

        // Description: 0.45 -> 0.80
        final descInterval = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
        );
        final descSlideY = (1.0 - descInterval.value) * 16.0;
        final descOpacity = descInterval.value.clamp(0.0, 1.0);

        // Bottom action bar: 0.55 -> 0.95
        final bottomInterval = CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.55, 0.95, curve: SpringOvershootCurve()),
        );
        final bottomSlideY = (1.0 - bottomInterval.value) * 28.0;
        final bottomOpacity = bottomInterval.value.clamp(0.0, 1.0);

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E4E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Animated Food Image with Scale-In & Floating Micro-Oscillation
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Transform.scale(
                      scale: imageScale,
                      child: Opacity(
                        opacity: imageOpacity,
                        child: Image.asset(
                          widget.item.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.fastfood_rounded,
                            size: 100,
                            color: Color(0xFF18181A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Title and Discount Badge Row
              Transform.translate(
                offset: Offset(0, titleSlideY),
                child: Opacity(
                  opacity: titleOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF18181A),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: badgeScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.discount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Transform.translate(
                offset: Offset(0, subSlideY),
                child: Opacity(
                  opacity: subOpacity,
                  child: Text(
                    widget.item.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8F959E),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Staggered Detail Chips (Rating, Prep Time, Calories)
              Row(
                children: [
                  _buildAnimatedChip(
                    icon: Icons.star_rounded,
                    label: '${widget.item.rating} (1.2k)',
                    iconColor: Colors.amber,
                    startInterval: 0.35,
                    endInterval: 0.65,
                  ),
                  const SizedBox(width: 12),
                  _buildAnimatedChip(
                    icon: Icons.timer_outlined,
                    label: widget.item.prepTime,
                    iconColor: const Color(0xFFFF6B4A),
                    startInterval: 0.42,
                    endInterval: 0.72,
                  ),
                  const SizedBox(width: 12),
                  _buildAnimatedChip(
                    icon: Icons.local_fire_department_outlined,
                    label: widget.item.calories,
                    iconColor: Colors.orange,
                    startInterval: 0.50,
                    endInterval: 0.80,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description Text with Slide + Fade
              Transform.translate(
                offset: Offset(0, descSlideY),
                child: Opacity(
                  opacity: descOpacity,
                  child: Text(
                    widget.item.description,
                    style: const TextStyle(
                      color: Color(0xFF5F6570),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Price and Add to Cart Action Bar
              Transform.translate(
                offset: Offset(0, bottomSlideY),
                child: Opacity(
                  opacity: bottomOpacity,
                  child: Row(
                    children: [
                      // Total Price with rolling digit transition
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              color: Color(0xFF8F959E),
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                r'$ ',
                                style: TextStyle(
                                  color: Color(0xFFFF6B4A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              AnimatedSlideText(
                                text: totalPrice.toStringAsFixed(2),
                                duration: const Duration(milliseconds: 600),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF18181A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(width: 24),

                      // Add to Cart Button with spring scale tap
                      Expanded(
                        child: Transform.scale(
                          scale: _btnScale.value,
                          child: ElevatedButton(
                            onPressed: _handleAddToCartTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF18181A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _quantity > 0
                                    ? 'Added to Cart ($_quantity)'
                                    : 'Add to Cart',
                                key: ValueKey(_quantity),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required double startInterval,
    required double endInterval,
  }) {
    final chipAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutBack),
    );

    return Transform.scale(
      scale: (0.7 + 0.3 * chipAnim.value).clamp(0.7, 1.0),
      child: Opacity(
        opacity: chipAnim.value.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
