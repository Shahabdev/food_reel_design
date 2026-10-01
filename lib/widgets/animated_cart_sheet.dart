import 'package:flutter/material.dart';
import '../animations/spring_curve.dart';
import '../models/food_item.dart';
import 'animated_digit_text.dart';

class AnimatedCartSheet extends StatefulWidget {
  final Map<String, int> cart;
  final List<FoodItem> allFoodItems;
  final double totalPrice;
  final int totalCount;
  final void Function(String id) onAdd;
  final void Function(String id) onRemove;
  final VoidCallback onCheckout;

  const AnimatedCartSheet({
    super.key,
    required this.cart,
    required this.allFoodItems,
    required this.totalPrice,
    required this.totalCount,
    required this.onAdd,
    required this.onRemove,
    required this.onCheckout,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, int> cart,
    required List<FoodItem> allFoodItems,
    required double totalPrice,
    required int totalCount,
    required void Function(String id) onAdd,
    required void Function(String id) onRemove,
    required VoidCallback onCheckout,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return AnimatedCartSheet(
          cart: cart,
          allFoodItems: allFoodItems,
          totalPrice: totalPrice,
          totalCount: totalCount,
          onAdd: onAdd,
          onRemove: onRemove,
          onCheckout: onCheckout,
        );
      },
    );
  }

  @override
  State<AnimatedCartSheet> createState() => _AnimatedCartSheetState();
}

class _AnimatedCartSheetState extends State<AnimatedCartSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartEntries = widget.cart.entries.toList();

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.74,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              const SizedBox(height: 18),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Order',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18181A),
                    ),
                  ),
                  Text(
                    '${widget.totalCount} items',
                    style: const TextStyle(
                      color: Color(0xFF8F959E),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cart Items List with Staggered Entrance
              Expanded(
                child: widget.cart.isEmpty
                    ? const Center(
                        child: Text(
                          'Your cart is empty',
                          style: TextStyle(
                            color: Color(0xFF8F959E),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: cartEntries.length,
                        itemBuilder: (context, index) {
                          final entry = cartEntries[index];
                          final item = widget.allFoodItems.firstWhere(
                            (i) => i.id == entry.key,
                          );
                          final qty = entry.value;

                          // Staggered interval for row: 0.15 + index * 0.12
                          final start = (0.15 + index * 0.10).clamp(0.0, 0.75);
                          final end = (start + 0.25).clamp(0.0, 1.0);
                          final rowAnim = CurvedAnimation(
                            parent: _entranceController,
                            curve: Interval(start, end,
                                curve: Curves.easeOutCubic),
                          );

                          return Transform.translate(
                            offset: Offset(0, (1.0 - rowAnim.value) * 24.0),
                            child: Opacity(
                              opacity: rowAnim.value.clamp(0.0, 1.0),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset(
                                        item.imageAsset,
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.fastfood,
                                          size: 40,
                                          color: Color(0xFF18181A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Color(0xFF18181A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            r'$' +
                                                (item.price * qty)
                                                    .toStringAsFixed(2),
                                            style: const TextStyle(
                                              color: Color(0xFFFF6B4A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _circleQtyBtn(
                                          icon: Icons.remove,
                                          onTap: () {
                                            widget.onRemove(item.id);
                                            setState(() {});
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: AnimatedSlideText(
                                            text: '$qty',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        _circleQtyBtn(
                                          icon: Icons.add,
                                          onTap: () {
                                            widget.onAdd(item.id);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Divider(color: Color(0xFFF0F1F4)),
              const SizedBox(height: 8),

              // Total Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8F959E),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        r'$ ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B4A),
                        ),
                      ),
                      AnimatedSlideText(
                        text: widget.totalPrice.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Checkout Button with Last Entrance Stagger
              Builder(builder: (context) {
                final checkoutAnim = CurvedAnimation(
                  parent: _entranceController,
                  curve: const Interval(0.55, 0.95,
                      curve: SpringOvershootCurve()),
                );

                return Transform.translate(
                  offset: Offset(0, (1.0 - checkoutAnim.value) * 30.0),
                  child: Opacity(
                    opacity: checkoutAnim.value.clamp(0.0, 1.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.cart.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context);
                                widget.onCheckout();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _circleQtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E4E8)),
        ),
        child: Center(
          child: Icon(icon, size: 16, color: const Color(0xFF18181A)),
        ),
      ),
    );
  }
}
