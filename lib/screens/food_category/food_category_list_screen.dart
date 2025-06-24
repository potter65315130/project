import 'package:flutter/material.dart';
import 'package:health_mate/models/food_category_model.dart';
import 'package:health_mate/screens/food_category/food_item_list_screen.dart';

class FoodCategoryListScreen extends StatelessWidget {
  final List<FoodCategory> categories;

  const FoodCategoryListScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกจากหมวดหมู่')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
            title: Text(category.categoryName),
            trailing: const Icon(Icons.arrow_forward_ios),
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
