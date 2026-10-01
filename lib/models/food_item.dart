class FoodItem {
  final String id;
  final String name;
  final String subtitle;
  final String discount;
  final double price;
  final double rating;
  final String calories;
  final String prepTime;
  final String category;
  final String imageAsset;
  final String description;

  const FoodItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.discount,
    required this.price,
    required this.rating,
    required this.calories,
    required this.prepTime,
    required this.category,
    required this.imageAsset,
    required this.description,
  });
}
