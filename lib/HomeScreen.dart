import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'ProductDetailsScreen.dart';
import 'UserAccountManagementScreen.dart';
import 'UserAccountScreen.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  bool _isSearchVisible = false;

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.title ?? 'Customer Home'),
        backgroundColor: Colors.teal,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: MyApp.localeNotifier.value.languageCode,
                icon: const Icon(Icons.language, color: Colors.white),
                dropdownColor: Colors.white,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    MyApp.changeLocale(newValue);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'si',
                    child: Text('සිංහල'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search Products',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          Expanded(child: _buildAllProductsList(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleSearchBar,
        backgroundColor: Colors.teal,
        child: Icon(
          _isSearchVisible ? Icons.close : Icons.search,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              localizations?.user_menu ?? 'User Menu',
              style: const TextStyle(fontSize: 18),
            ),
            accountEmail: const Text('example@mail.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.teal, size: 40),
            ),
            decoration: const BoxDecoration(
              color: Colors.teal,
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            text: localizations?.home ?? 'Home',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.check_box,
            text: localizations?.account ?? 'Orders',
            onTap: () {
              Navigator.pop(context);
              _navigateToUserAccount();
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_circle,
            text: localizations?.account ?? 'Account',
            onTap: () {
              Navigator.pop(context);
              _navigateToUserAccountManagement();
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.exit_to_app,
            text: localizations?.logout ?? 'Logout',
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _navigateToUserAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserAccountScreen()),
    );
  }

  void _navigateToUserAccountManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserAccountManagementScreen()),
    );
  }

  Widget _buildAllProductsList(BuildContext context) {
    Stream<QuerySnapshot> productStream =
        FirebaseFirestore.instance.collection('products').snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: productStream,
      builder: (context, snapshot) {
        final localizations = AppLocalizations.of(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(localizations?.no_products ?? 'No products available.'),
          );
        }

        final products = snapshot.data!.docs.where((doc) {
          final productData = doc.data() as Map<String, dynamic>;
          final productName =
              productData['name']?.toString().toLowerCase() ?? '';
          return productName.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: products.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final productData = products[index].data() as Map<String, dynamic>;
            final productId = products[index].id;

            final List<dynamic>? imagePaths = productData['imagePaths'];
            final String firstImage = (imagePaths != null &&
                    imagePaths.isNotEmpty &&
                    imagePaths.first is String)
                ? imagePaths.first
                : 'https://via.placeholder.com/150';

            return FutureBuilder<double>(
              future: _getAverageRating(productId),
              builder: (context, ratingSnapshot) {
                double averageRating = ratingSnapshot.data ?? 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (firstImage.startsWith('http') ||
                                  firstImage.startsWith('https'))
                              ? Image.network(
                                  firstImage,
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(firstImage),
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productData['name'] ??
                                    localizations?.product_name ??
                                    'Product Name',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  '${localizations?.brand ?? "Brand"}: ${productData['brand'] ?? 'No Brand'}'),
                              Text(
                                  '${localizations?.price_per_hour ?? "Price per Hour"}: \$${productData['pricePerHour'] ?? 0}'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    averageRating > 0
                                        ? averageRating.toStringAsFixed(1)
                                        : 'No Ratings',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _navigateToProductDetails(
                                    productData, productId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('More Info'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<double> _getAverageRating(String productId) async {
    print("Fetching ratings for product ID: $productId");
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('productId', isEqualTo: productId)
          .get();

      print("Orders found: ${ordersSnapshot.docs.length}");

      double totalRating = 0.0;
      int ratingCount = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('rating') && data['rating'] != null) {
          totalRating += (data['rating'] as num).toDouble();
          ratingCount++;
        }
      }

      print("Total ratings: $totalRating, Rating count: $ratingCount");
      return ratingCount > 0 ? totalRating / ratingCount : 0.0;
    } catch (e) {
      print("Error fetching ratings: $e");
      return 0.0;
    }
  }

  void _navigateToProductDetails(
      Map<String, dynamic> productData, String productId) {
    print("product id prom home------");
    print(productId);
    final updatedData = {
      ...productData,
      'imagePaths':
          productData['imagePaths'] ?? ['https://via.placeholder.com/300'],
      'productId': productId,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productData: updatedData,
          pid: productId,
        ),
      ),
    );
  }
}
