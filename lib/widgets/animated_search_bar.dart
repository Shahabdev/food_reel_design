import 'package:flutter/material.dart';
import '../animations/spring_curve.dart';

class AnimatedSearchBar extends StatefulWidget {
  final Animation<double> entranceProgress;
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const AnimatedSearchBar({
    super.key,
    required this.entranceProgress,
    required this.searchController,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _filterPressController;
  late Animation<double> _filterScale;
  late Animation<double> _filterRotation;

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _filterPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _filterScale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _filterPressController,
        curve: Curves.easeInOut,
      ),
    );

    _filterRotation = Tween<double>(begin: 0.0, end: -0.18).animate(
      CurvedAnimation(
        parent: _filterPressController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _filterPressController.dispose();
    super.dispose();
  }

  void _onFilterTapDown(TapDownDetails details) {
    _filterPressController.forward();
  }

  void _onFilterTapUp(TapUpDetails details) {
    _filterPressController.reverse();
    widget.onFilterTap();
  }

  void _onFilterTapCancel() {
    _filterPressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.entranceProgress, _filterPressController]),
      builder: (context, child) {
        // Search bar entrance: 0.28 -> 0.55
        final searchInterval = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: const Interval(0.28, 0.55, curve: Curves.easeOutCubic),
        );
        final searchOpacity = searchInterval.value;
        final searchSlideY = (1.0 - searchInterval.value) * 22.0;

        // Filter button scale entrance: 0.35 -> 0.60 with spring overshoot
        final filterEntrance = CurvedAnimation(
          parent: widget.entranceProgress,
          curve: const Interval(0.35, 0.60, curve: SpringOvershootCurve()),
        );
        final filterBaseScale = 0.85 + 0.15 * filterEntrance.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              // Search Input Field
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, searchSlideY),
                  child: Opacity(
                    opacity: searchOpacity.clamp(0.0, 1.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _isFocused
                              ? const Color(0xFF18181A)
                              : const Color(0xFFECEEF2),
                          width: _isFocused ? 1.2 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isFocused
                                ? const Color.fromRGBO(0, 0, 0, 0.06)
                                : const Color.fromRGBO(0, 0, 0, 0.02),
                            blurRadius: _isFocused ? 16 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0.8,
                              end: searchInterval.value >= 1.0 ? 1.0 : 0.8,
                            ),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF9FA5B0),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Focus(
                              onFocusChange: (focused) {
                                setState(() {
                                  _isFocused = focused;
                                });
                              },
                              child: TextField(
                                controller: widget.searchController,
                                onChanged: widget.onChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search for fast food...',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFFA4A9B4).withValues(
                                      alpha: searchOpacity.clamp(0.0, 1.0),
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF18181A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (widget.searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: widget.onClear,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF9FA5B0),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Filter Button with Entrance Scale and Interactive Spring Rotation Tap
              Transform.translate(
                offset: Offset(0, searchSlideY),
                child: Opacity(
                  opacity: searchOpacity.clamp(0.0, 1.0),
                  child: GestureDetector(
                    onTapDown: _onFilterTapDown,
                    onTapUp: _onFilterTapUp,
                    onTapCancel: _onFilterTapCancel,
                    child: Transform.scale(
                      scale: filterBaseScale * _filterScale.value,
                      child: Transform.rotate(
                        angle: _filterRotation.value,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF18181A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(24, 24, 26, 0.22),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
