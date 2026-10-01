import 'package:flutter/material.dart';

/// Controller that coordinates an automated 8-12 second promotional sequence
/// perfect for Instagram Reels, TikTok, or marketing screen captures.
class ReelAnimationController extends ChangeNotifier {
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Hooks to screen actions
  VoidCallback? onResetScreen;
  Future<void> Function()? onPlayEntrance;
  Future<void> Function(int categoryIndex)? onSelectCategory;
  Future<void> Function(String itemId)? onSimulateAddItem;
  VoidCallback? onOpenCart;
  VoidCallback? onCloseCart;

  void bind({
    required VoidCallback onResetScreen,
    required Future<void> Function() onPlayEntrance,
    required Future<void> Function(int categoryIndex) onSelectCategory,
    required Future<void> Function(String itemId) onSimulateAddItem,
    required VoidCallback onOpenCart,
    required VoidCallback onCloseCart,
  }) {
    this.onResetScreen = onResetScreen;
    this.onPlayEntrance = onPlayEntrance;
    this.onSelectCategory = onSelectCategory;
    this.onSimulateAddItem = onSimulateAddItem;
    this.onOpenCart = onOpenCart;
    this.onCloseCart = onCloseCart;
  }

  Future<void> startReelAnimation() async {
    if (_isPlaying) return;
    _isPlaying = true;
    notifyListeners();

    try {
      // 1. Reset screen (clear cart, close sheet, reset scroll & entrance)
      onCloseCart?.call();
      onResetScreen?.call();
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Play cinematic staggered screen entrance (Header -> Headline -> Search -> Categories -> Cards)
      if (onPlayEntrance != null) {
        await onPlayEntrance!();
      }
      await Future.delayed(const Duration(milliseconds: 1000));

      // 3. Simulate selecting Noodles Twistara -> flies slowly into bottom cart!
      if (onSimulateAddItem != null) {
        await onSimulateAddItem!('noodles');
      }
      await Future.delayed(const Duration(milliseconds: 2200));

      // 4. Smooth category swipe to "Food" / category index 4
      if (onSelectCategory != null) {
        await onSelectCategory!(4);
      }
      await Future.delayed(const Duration(milliseconds: 1600));

      // 5. Swipe back to "All" (index 2)
      if (onSelectCategory != null) {
        await onSelectCategory!(2);
      }
      await Future.delayed(const Duration(milliseconds: 1400));

      // 6. Simulate adding Pizza Sicilia -> second item flies gracefully into bottom cart!
      if (onSimulateAddItem != null) {
        await onSimulateAddItem!('pizza');
      }
      await Future.delayed(const Duration(milliseconds: 2400));

      // 7. Dynamically open the floating bottom cart sheet with staggered item animations
      onOpenCart?.call();
      await Future.delayed(const Duration(milliseconds: 4200));

      // 8. Close cart sheet to return to the beautifully populated screen
      onCloseCart?.call();
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void stop() {
    _isPlaying = false;
    notifyListeners();
  }
}
