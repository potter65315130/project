import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:health_mate/models/food/food_category_model.dart';
import 'package:health_mate/models/food/food_item_model.dart';

class FoodDataService {
  List<FoodCategory> _categories = [];
  List<FoodItem> _allItems = [];
  bool _isLoaded = false;

  Future<void> loadFoodData() async {
    if (_isLoaded) return;

    final String jsonString = await rootBundle.loadString(
      'assets/data/food_categories.json',
    );
    final data = json.decode(jsonString);

    final List<dynamic> categoryList = data['food_categories'];
    _categories =
        categoryList.map((json) => FoodCategory.fromJson(json)).toList();

    _allItems = _categories.expand((category) => category.items).toList();
    _isLoaded = true;
  }

  List<FoodCategory> getCategories() => _categories;

  List<FoodItem> searchFood(String query) {
    if (query.isEmpty) {
      return [];
    }
    final lowerCaseQuery = query.toLowerCase();
    return _allItems
        .where((item) => item.name.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }
}
