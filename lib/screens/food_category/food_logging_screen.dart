import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_mate/screens/food_category/food_category_list_screen.dart';
import 'package:health_mate/screens/history/food_log_history_screen.dart';
import 'package:health_mate/services/food_data_service.dart';
import 'package:health_mate/widgets/food_log_dialog.dart';
import 'package:intl/intl.dart';
import 'package:health_mate/models/food/food_entry_model.dart';
import 'package:health_mate/models/food/food_item_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:health_mate/screens/food_category/barcode_scanner_screen.dart';
import 'package:health_mate/widgets/food_entry_detail_dialog.dart';

const Color _darkBgColor = Color(0xFF1A1A1A);
const Color _darkElementColor = Color(0xFF2A2A2A);
const Color _accentColor = Color(0xFFB4F82B);
const Color _lightTextColor = Colors.white;
const Color _mediumTextColor = Color(0xFFB0B0B0);

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  final FoodDataService _foodDataService = FoodDataService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  bool _isLoading = false;
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _foodDataService.loadFoodData();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
        _searchResults = _foodDataService.searchFood(query);
      });
    } else {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final String? barcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (barcode != null && barcode.isNotEmpty && mounted) {
        _fetchFoodDataFromApi(barcode);
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการสแกน: $e');
    }
  }

  Future<void> _fetchFoodDataFromApi(String barcode) async {
    setState(() => _isLoading = true);

    final url = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {'fields': 'product_name,nutriments'},
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final nutriments = product['nutriments'];
          final foodItem = FoodItem(
            name: product['product_name'] ?? 'ไม่พบชื่อสินค้า',
            calories: (nutriments['energy-kcal_100g'] ?? 0.0).toDouble(),
            protein: (nutriments['proteins_100g'] ?? 0.0).toDouble(),
            carbs: (nutriments['carbohydrates_100g'] ?? 0.0).toDouble(),
            fat: (nutriments['fat_100g'] ?? 0.0).toDouble(),
          );
          if (mounted) {
            showFoodLogDialog(context: context, item: foodItem);
          }
        } else {
          _showErrorSnackBar('ไม่พบข้อมูลสินค้าสำหรับบาร์โค้ดนี้');
        }
      } else {
        _showErrorSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _darkBgColor,
        appBar: AppBar(
          backgroundColor: _darkBgColor,
          elevation: 0,
          title: const Text(
            'บันทึกอาหาร',
            style: TextStyle(color: _lightTextColor),
          ),
          bottom: const TabBar(
            labelColor: _accentColor,
            unselectedLabelColor: _mediumTextColor,
            indicatorColor: _accentColor,
            tabs: [Tab(text: 'ค้นหา'), Tab(text: 'รายการโปรด')],
          ),
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: _accentColor),
                )
                : TabBarView(
                  children: [
                    buildSearchTab(context),
                    buildFavoritesTab(context),
                  ],
                ),
      ),
    );
  }

  Widget buildSearchTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: _lightTextColor),
            decoration: InputDecoration(
              hintText: 'ค้นหาจากชื่อ...',
              hintStyle: const TextStyle(color: _mediumTextColor),
              prefixIcon: const Icon(Icons.search, color: _accentColor),
              suffixIcon:
                  _isSearching
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: _mediumTextColor),
                        onPressed: () => _searchController.clear(),
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _darkElementColor,
            ),
          ),
        ),
        Expanded(
          child: _isSearching ? buildSearchResults() : buildDefaultSearchBody(),
        ),
      ],
    );
  }

  Widget buildDefaultSearchBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: Icons.category_outlined,
                label: 'หมวดหมู่',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FoodCategoryListScreen(
                            categories: _foodDataService.getCategories(),
                          ),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.history_outlined,
                label: 'ย้อนหลัง',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FoodLogHistoryScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.qr_code_scanner_outlined,
                label: 'สแกน',
                onTap: _scanBarcode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: _darkElementColor),
          const SizedBox(height: 16),
          const Text(
            'รายการวันนี้',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _lightTextColor,
            ),
          ),
          const SizedBox(height: 8),
          buildTodaysLogList(),
        ],
      ),
    );
  }

  Widget buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบรายการอาหารที่ค้นหา',
          style: TextStyle(color: _mediumTextColor),
        ),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          title: Text(
            item.name,
            style: const TextStyle(color: _lightTextColor),
          ),
          subtitle: Text(
            '${item.calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(color: _mediumTextColor),
          ),
          onTap: () {
            showFoodLogDialog(context: context, item: item);
          },
        );
      },
    );
  }

  Widget buildTodaysLogList() {
    if (_uid == null) {
      return const Center(
        child: Text(
          'กรุณาเข้าสู่ระบบ',
          style: TextStyle(color: _mediumTextColor),
        ),
      );
    }
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<List<FoodEntryModel>>(
      stream: _firestoreService.getFoodEntriesStream(_uid, todayString),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _accentColor),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'เกิดข้อผิดพลาด: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'ยังไม่มีรายการที่บันทึกในวันนี้',
                style: TextStyle(color: _mediumTextColor),
              ),
            ),
          );
        }
        final entries = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              title: Text(
                entry.name,
                style: const TextStyle(color: _lightTextColor),
              ),
              subtitle: Text(
                '${entry.calories.toStringAsFixed(0)} kcal - ${DateFormat.Hm().format(entry.timestamp)}',
                style: const TextStyle(color: _mediumTextColor),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'P:${entry.protein.toStringAsFixed(0)} C:${entry.carbs.toStringAsFixed(0)} F:${entry.fat.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _mediumTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      if (entry.id != null) {
                        context.read<HomeProvider>().deleteFoodLog(entry);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ลบรายการแล้ว'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                showFoodEntryDetailDialog(context: context, entry: entry);
              },
            );
          },
        );
      },
    );
  }

  Widget buildFavoritesTab(BuildContext context) {
    if (_uid == null) {
      return const Center(
        child: Text(
          'กรุณาเข้าสู่ระบบเพื่อใช้รายการโปรด',
          style: TextStyle(color: _mediumTextColor),
        ),
      );
    }
    return StreamBuilder<List<FoodItem>>(
      stream: _firestoreService.getFavoritesStream(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _accentColor),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'เกิดข้อผิดพลาด: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'คุณยังไม่มีรายการโปรด',
              style: TextStyle(color: _mediumTextColor),
            ),
          );
        }

        final favorites = snapshot.data!;
        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final item = favorites[index];
            return ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(
                item.name,
                style: const TextStyle(color: _lightTextColor),
              ),
              subtitle: Text(
                '${item.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(color: _mediumTextColor),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  _firestoreService.removeFavorite(_uid, item);
                },
              ),
              onTap: () {
                showFoodLogDialog(context: context, item: item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: _darkElementColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: _accentColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _lightTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
