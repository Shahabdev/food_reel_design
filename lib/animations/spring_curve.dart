import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// Smooth overshooting spring curve for snappy, tactile micro-interactions
class SpringOvershootCurve extends Curve {
  final double damping;
  final double stiffness;

  const SpringOvershootCurve({
    this.damping = 12.0,
    this.stiffness = 180.0,
  });

  @override
  double transformInternal(double t) {
    if (t >= 1.0) return 1.0;
    if (t <= 0.0) return 0.0;
    // Damped harmonic oscillator formula
    final double omega = math.sqrt(stiffness);
    final double decay = math.exp(-damping * t * 0.5);
    return 1.0 - decay * math.cos(omega * t);
  }
}

/// Subtle bounce curve for badge pop-ins and button release
class GentleBounceCurve extends Curve {
  const GentleBounceCurve();

  @override
  double transformInternal(double t) {
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    // Elastic overshoot: 1 + 2^(-10t) * sin((t - 0.1) * 2pi / 0.4)
    final double s = 0.4 / 4;
    return math.pow(2, -10 * t) * math.sin((t - s) * (2 * math.pi) / 0.4) + 1;
  }
}
