import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/food_category.dart';

class AnimatedCategoryArc extends StatefulWidget {
  final Animation<double> entranceProgress;
  final List<FoodCategory> categories;
  final String selectedCategory;
  final double wheelOffset;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final VoidCallback onDragStart;

  const AnimatedCategoryArc({
    super.key,
    required this.entranceProgress,
    required this.categories,
    required this.selectedCategory,
    required this.wheelOffset,
    required this.onCategorySelected,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragStart,
  });

  @override
  State<AnimatedCategoryArc> createState() => _AnimatedCategoryArcState();
}

class _AnimatedCategoryArcState extends State<AnimatedCategoryArc> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.entranceProgress,
      builder: (context, _) {
        // Overall category arc entrance: 0.40 -> 0.70
        final arcEntranceInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: const Interval(0.40, 0.70, curve: Curves.easeOutCubic),
        );
        final arcOpacity = arcEntranceInterval.value;
        final arcSlideX = (1.0 - arcEntranceInterval.value) * 35.0;

        return Transform.translate(
          offset: Offset(arcSlideX, 0),
          child: Opacity(
            opacity: arcOpacity.clamp(0.0, 1.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                const double widgetHeight = 168.0;

                // Circular dome geometry
                const double radius = 420.0;
                final double centerX = screenWidth / 2;
                const double apexY = 28.0;
                final double centerY = apexY + radius;
                const double angleStep = 0.2;

                return ClipRect(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) => widget.onDragStart(),
                    onHorizontalDragUpdate: (details) =>
                        widget.onDragUpdate(details.primaryDelta ?? 0.0),
                    onHorizontalDragEnd: (details) =>
                        widget.onDragEnd(details.primaryVelocity ?? 0.0),
                    child: SizedBox(
                      height: widgetHeight,
                      width: screenWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. Curved grey arc band background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: FigmaCategoryArcPainter(
                                centerX: centerX,
                              ),
                            ),
                          ),

                          // 2. Category items placed along the arc
                          ...List.generate(widget.categories.length, (index) {
                            final category = widget.categories[index];
                            final double diff = index - widget.wheelOffset;
                            final double angle = diff * angleStep;

                            final double itemCenterX =
                                centerX + radius * math.sin(angle);
                            final double itemCenterY =
                                centerY - radius * math.cos(angle);

                            final double absDiff = diff.abs();
                            final bool isCenter = absDiff < 0.45;

                            // Scale interpolation: center is 1.06, sides gently scale down to 0.94
                            final double scaleInterp = (1.06 - absDiff * 0.08)
                                .clamp(0.92, 1.06);

                            // Per-item staggered entrance: items cascade slightly
                            final itemDelay = (index * 0.03).clamp(0.0, 0.25);
                            final itemAnim = CurvedAnimation(
                              parent: widget.entranceProgress,
                              curve: Interval(
                                (0.42 + itemDelay).clamp(0.0, 0.95),
                                (0.65 + itemDelay).clamp(0.0, 1.0),
                                curve: Curves.easeOutBack,
                              ),
                            );
                            final itemScaleEntrance = itemAnim.value;

                            // Visible arc span check
                            if (absDiff > 2.15 ||
                                itemCenterX < -40 ||
                                itemCenterX > screenWidth + 40) {
                              return const SizedBox.shrink();
                            }

                            // Smooth fade near edges
                            final double edgeOpacity = (1.0 -
                                    (absDiff - 2.0).clamp(0.0, 0.15) / 0.15)
                                .clamp(0.0, 1.0);

                            return Positioned(
                              left: itemCenterX - 45,
                              top: itemCenterY,
                              child: Opacity(
                                opacity: (edgeOpacity * itemScaleEntrance)
                                    .clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: scaleInterp *
                                      (0.85 + 0.15 * itemScaleEntrance),
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        widget.onCategorySelected(index),
                                    child: SizedBox(
                                      width: 90,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // White circular icon container
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromRGBO(
                                                    0,
                                                    0,
                                                    0,
                                                    0.04,
                                                  ),
                                                  blurRadius: isCenter ? 12 : 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Image.asset(
                                                  category.imageAsset,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (context, error,
                                                          stackTrace) {
                                                    return Icon(
                                                      category.iconFallback,
                                                      color: const Color(
                                                        0xFF18181A,
                                                      ),
                                                      size: 26,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 14),

                                          // Category label with smooth weight & color transition
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                              milliseconds: 450,
                                            ),
                                            style: TextStyle(
                                              color: isCenter
                                                  ? const Color(0xFF18181A)
                                                  : const Color(0xFF8F959E),
                                              fontSize: isCenter ? 14 : 13,
                                              fontWeight: isCenter
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              letterSpacing: -0.2,
                                              fontFamily: 'Roboto',
                                            ),
                                            child: Text(
                                              category.title,
                                              maxLines: 1,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Smooth sliding/morphing indicator pill
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 450,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            width: isCenter ? 38 : 0,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF18181A),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class FigmaCategoryArcPainter extends CustomPainter {
  final double centerX;

  const FigmaCategoryArcPainter({required this.centerX});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft grey circular arc band in the background
    final arcPaint = Paint()
      ..color = const Color(0xFFEFF1F4)
      ..style = PaintingStyle.fill;

    final arcPath = Path();
    arcPath.moveTo(0, 62);
    arcPath.quadraticBezierTo(centerX, 0, w, 62);
    arcPath.lineTo(w, h);
    arcPath.lineTo(0, h);
    arcPath.close();

    canvas.drawPath(arcPath, arcPaint);

    // 2. White food cards dome surface at the bottom
    final whitePaint = Paint()
      ..color = const Color(0xFFF9FAFC)
      ..style = PaintingStyle.fill;

    final whitePath = Path();
    whitePath.moveTo(0, h);
    whitePath.lineTo(0, h);
    whitePath.quadraticBezierTo(centerX, 144, w, h);
    whitePath.lineTo(w, h);
    whitePath.close();

    canvas.drawPath(whitePath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant FigmaCategoryArcPainter oldDelegate) {
    return oldDelegate.centerX != centerX;
  }
}
