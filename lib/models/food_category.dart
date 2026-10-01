import 'package:flutter/material.dart';

class FoodCategory {
  final String id;
  final String title;
  final String imageAsset;
  final IconData iconFallback;

  const FoodCategory({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.iconFallback,
  });
}
