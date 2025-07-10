import 'package:flutter/material.dart';
import 'package:health_mate/models/food/food_category_model.dart';
import 'package:health_mate/screens/food_category/food_item_list_screen.dart';

// --- UI THEME CONSTANTS (ควร import มาจากที่เดียว) ---
const Color _darkBgColor = Color(0xFF121212);
const Color _lightTextColor = Colors.white;
const Color _mediumTextColor = Color(0xFFB0B0B0);
// --- END UI THEME CONSTANTS ---

class FoodCategoryListScreen extends StatelessWidget {
  final List<FoodCategory> categories;

  const FoodCategoryListScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBgColor,
      appBar: AppBar(
        title: const Text(
          'เลือกจากหมวดหมู่',
          style: TextStyle(color: _lightTextColor),
        ),
        backgroundColor: _darkBgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _lightTextColor),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
            title: Text(
              category.categoryName,
              style: const TextStyle(color: _lightTextColor),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: _mediumTextColor,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FoodItemListScreen(
                        categoryName: category.categoryName,
                        items: category.items,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
