import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlyingFoodData {
  final Key key;
  final Offset startOffset;
  final Size startSize;
  final Offset endOffset;
  final String imageAsset;
  final VoidCallback? onComplete;

  FlyingFoodData({
    required this.key,
    required this.startOffset,
    required this.startSize,
    required this.endOffset,
    required this.imageAsset,
    this.onComplete,
  });
}

/// Global/Scoped manager for flying food animations
class CartFlyManager {
  static final CartFlyManager instance = CartFlyManager._();
  CartFlyManager._();

  final List<void Function(FlyingFoodData)> _listeners = [];

  void addListener(void Function(FlyingFoodData) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(FlyingFoodData) listener) {
    _listeners.remove(listener);
  }

  void flyItem({
    required Offset startOffset,
    required Size startSize,
    required Offset endOffset,
    required String imageAsset,
    VoidCallback? onComplete,
  }) {
    final data = FlyingFoodData(
      key: UniqueKey(),
      startOffset: startOffset,
      startSize: startSize,
      endOffset: endOffset,
      imageAsset: imageAsset,
      onComplete: onComplete,
    );
    for (final listener in _listeners) {
      listener(data);
    }
  }
}

/// Overlay widget that hosts and animates the flying food proxy
class CartFlyOverlay extends StatefulWidget {
  final Widget child;

  const CartFlyOverlay({super.key, required this.child});

  @override
  State<CartFlyOverlay> createState() => _CartFlyOverlayState();
}

class _CartFlyOverlayState extends State<CartFlyOverlay> {
  final List<FlyingFoodData> _activeFlights = [];

  @override
  void initState() {
    super.initState();
    CartFlyManager.instance.addListener(_onNewFlight);
  }

  @override
  void dispose() {
    CartFlyManager.instance.removeListener(_onNewFlight);
    super.dispose();
  }

  void _onNewFlight(FlyingFoodData data) {
    if (!mounted) return;
    setState(() {
      _activeFlights.add(data);
    });
  }

  void _removeFlight(FlyingFoodData data) {
    if (!mounted) return;
    setState(() {
      _activeFlights.remove(data);
    });
    data.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._activeFlights.map(
          (data) => _FlyingFoodItemWidget(
            key: data.key,
            data: data,
            onLanded: () => _removeFlight(data),
          ),
        ),
      ],
    );
  }
}

class _FlyingFoodItemWidget extends StatefulWidget {
  final FlyingFoodData data;
  final VoidCallback onLanded;

  const _FlyingFoodItemWidget({
    super.key,
    required this.data,
    required this.onLanded,
  });

  @override
  State<_FlyingFoodItemWidget> createState() => _FlyingFoodItemWidgetState();
}

class _FlyingFoodItemWidgetState extends State<_FlyingFoodItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) {
      widget.onLanded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Calculate quadratic Bezier position
  Offset _calculateBezierPoint(double t) {
    final start = widget.data.startOffset;
    final end = widget.data.endOffset;

    // Arcing control point: bows out slightly and arcs upward
    final double controlX = (start.dx + end.dx) / 2.0 - 40.0;
    final double controlY = math.min(start.dy, end.dy) - 50.0;

    final double oneMinusT = 1.0 - t;
    final double x =
        oneMinusT * oneMinusT * start.dx +
        2 * oneMinusT * t * controlX +
        t * t * end.dx;
    final double y =
        oneMinusT * oneMinusT * start.dy +
        2 * oneMinusT * t * controlY +
        t * t * end.dy;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        final position = _calculateBezierPoint(t);

        // Scale goes from 1.0 down to ~0.26
        final double scale = 1.0 - 0.74 * t;

        // Opacity stays 1.0 until 75%, then fades quickly into the cart
        final double opacity = t < 0.75 ? 1.0 : (1.0 - (t - 0.75) / 0.25);

        // Gentle rotational spin
        final double rotation = t * 0.45;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Container(
                    width: widget.data.startSize.width,
                    height: widget.data.startSize.height,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B4A).withValues(alpha: 0.35 * (1 - t)),
                          blurRadius: 18 * (1 - t),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      widget.data.imageAsset,
                      fit: BoxFit.contain,
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
