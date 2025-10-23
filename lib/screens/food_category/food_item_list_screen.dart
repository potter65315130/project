import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_mate/models/food/food_item_model.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:health_mate/widgets/food_log_dialog.dart';

const Color _darkBgColor = Color(0xFF121212);
const Color _lightTextColor = Colors.white;
const Color _mediumTextColor = Color(0xFFB0B0B0);

class FoodItemListScreen extends StatelessWidget {
  final String categoryName;
  final List<FoodItem> items;
  final FirestoreService _firestoreService = FirestoreService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  FoodItemListScreen({
    super.key,
    required this.categoryName,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBgColor,
      appBar: AppBar(
        title: Text(
          categoryName,
          style: const TextStyle(color: _lightTextColor),
        ),
        backgroundColor: _darkBgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _lightTextColor),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream:
            _uid != null
                ? _firestoreService.getFavoritesStream(_uid)
                : Stream.value([]),
        builder: (context, snapshot) {
          final favoriteItems = snapshot.data ?? [];
          final favoriteNames = favoriteItems.map((fav) => fav.name).toSet();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isFavorite = favoriteNames.contains(item.name);

              return ListTile(
                title: Text(
                  item.name,
                  style: const TextStyle(color: _lightTextColor),
                ),
                subtitle: Text(
                  '${item.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(color: _mediumTextColor),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    if (_uid != null) {
                      if (isFavorite) {
                        _firestoreService.removeFavorite(_uid, item);
                      } else {
                        _firestoreService.addFavorite(_uid, item);
                      }
                    }
                  },
                ),
                onTap: () {
                  showFoodLogDialog(context: context, item: item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
