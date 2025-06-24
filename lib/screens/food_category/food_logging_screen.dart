import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health_mate/screens/food_category/food_category_list_screen.dart';
import 'package:health_mate/screens/history/food_log_history_screen.dart';
import 'package:health_mate/services/food_data_service.dart';
import 'package:health_mate/widgets/food_log_dialog.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:health_mate/models/food_entry_model.dart';
import 'package:health_mate/models/food_item_model.dart';
import 'package:health_mate/providers/home_provider.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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

  // --- UI Helpers ---
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // --- Barcode Scanning Logic ---
  Future<void> _scanBarcode() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BarcodeScannerScreen(
                onBarcodeDetected: (barcode) {
                  Navigator.of(context).pop();
                  _fetchFoodDataFromApi(barcode);
                },
              ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเปิดกล้อง: $e');
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
          // ใช้ Dialog กลาง
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

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('บันทึกอาหาร'),
          bottom: const TabBar(
            tabs: [Tab(text: 'ค้นหา'), Tab(text: 'รายการโปรด')],
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
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
            decoration: InputDecoration(
              hintText: 'ค้นหาจากชื่อ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _isSearching
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: Icons.category_outlined,
                label: 'ค้นหาจากหมวด',
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
                label: 'ดูบันทึกย้อนหลัง',
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
                label: 'สแกนบาร์โค้ด',
                onTap: _scanBarcode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'รายการวันนี้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          buildTodaysLogList(),
        ],
      ),
    );
  }

  Widget buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('ไม่พบรายการอาหารที่ค้นหา'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('${item.calories.toStringAsFixed(0)} kcal'),
          onTap: () {
            showFoodLogDialog(context: context, item: item);
          },
        );
      },
    );
  }

  Widget buildTodaysLogList() {
    if (_uid == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
    }
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<List<FoodEntryModel>>(
      stream: _firestoreService.getFoodEntriesStream(_uid, todayString),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('ยังไม่มีรายการที่บันทึกในวันนี้')),
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
              title: Text(entry.name),
              subtitle: Text(
                '${entry.calories.toStringAsFixed(0)} kcal - ${DateFormat.Hm().format(entry.timestamp)}',
              ),
              trailing: Text(
                'P:${entry.protein.toStringAsFixed(0)} C:${entry.carbs.toStringAsFixed(0)} F:${entry.fat.toStringAsFixed(0)}',
              ),
            );
          },
        );
      },
    );
  }

  Widget buildFavoritesTab(BuildContext context) {
    if (_uid == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อใช้รายการโปรด'));
    }
    return StreamBuilder<List<FoodItem>>(
      stream: _firestoreService.getFavoritesStream(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('คุณยังไม่มีรายการโปรด'));
        }

        final favorites = snapshot.data!;
        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final item = favorites[index];
            return ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(item.name),
              subtitle: Text('${item.calories.toStringAsFixed(0)} kcal'),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  const BarcodeScannerScreen({super.key, required this.onBarcodeDetected});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    try {
      await controller.toggleTorch();
      setState(() {
        isTorchOn = !isTorchOn;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling torch: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนบาร์โค้ด'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.grey,
            ),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              controller.stop();
              widget.onBarcodeDetected(code);
            }
          }
        },
      ),
    );
  }
}
