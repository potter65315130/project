import 'package:health_mate/models/food_item_model.dart';

class FoodCategory {
  final String categoryName;
  final String icon;
  final List<FoodItem> items;

  FoodCategory({
    required this.categoryName,
    required this.icon,
    required this.items,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<FoodItem> foodItems =
        itemsList.map((i) => FoodItem.fromJson(i)).toList();

    return FoodCategory(
      categoryName: json['categoryName'] as String,
      icon: json['icon'] as String,
      items: foodItems,
    );
  }
}
