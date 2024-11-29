import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  String pid;

  ProductDetailsScreen({super.key, required this.productData,required this.pid});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? _sellerData;
  bool _isLoading = true;
  final TextEditingController _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  Future<void> _fetchSellerData() async {
    try {
      String userId = widget.productData['userId'] ?? '';
      if (userId.isNotEmpty) {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            _sellerData = userDoc.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print('Error fetching seller data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to place an order.')),
      );
      return;
    }

    String hoursText = _hoursController.text;
    if (hoursText.isEmpty || int.tryParse(hoursText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of hours.')),
      );
      return;
    }

    int hours = int.parse(hoursText);

    var uuid = const Uuid();
    String orderId = uuid.v4();

    print("product id------");
    print(widget.pid);

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'productId': widget.pid ?? '',
        'productName': widget.productData['name'] ?? 'Unnamed Product',
        'pricePerHour': widget.productData['pricePerHour'] ?? 0,
        'withOperator': widget.productData['withOperator'] ?? false,
        'buyerId': currentUser.uid,
        'sellerId': widget.productData['userId'] ?? '',
        'orderDate': Timestamp.now(),
        'status': 'Not decided',
        'hours': hours,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  void _showOrderConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How many hours would you like to rent this product?'),
              const SizedBox(height: 16),
              TextField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter hours',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _placeOrder();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productData['name'] ?? 'Product Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.label,
                      label: 'Name',
                      value: widget.productData['name'] ?? 'No Name',
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.branding_watermark,
                      label: 'Brand',
                      value: widget.productData['brand'] ?? 'No Brand',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.description,
                      label: 'Description',
                      value: widget.productData['description'] ?? 'No Description',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.attach_money,
                      label: 'Price per Hour',
                      value: '\$${widget.productData['pricePerHour'] ?? 0}',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.engineering,
                      label: 'With Operator',
                      value: widget.productData['withOperator'] == true ? "Yes" : "No",
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Add any desired functionality here
                            },
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Contact Seller'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _showOrderConfirmationDialog,
                            icon: const Icon(Icons.payment),
                            label: const Text('Buy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSellerDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    // Extract image paths from productData
    List<String> imagePaths = widget.productData['imagePaths']?.cast<String>() ?? [];

    if (imagePaths.isEmpty) {
      return const Center(child: Text('No images available.'));
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePaths[0]),
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholderImage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              if (imagePaths.length > 1)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePaths[1]),
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                  ),
                ),
              if (imagePaths.length > 2) const SizedBox(height: 8),
              if (imagePaths.length > 2)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePaths[2]),
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholderImage(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Image.asset(
      'assets/placeholder.png', // Replace with the actual path to your placeholder image
      fit: BoxFit.cover,
    );
  }




  Widget _buildImage(dynamic image) {
    if (image is String && (image.startsWith('http') || image.startsWith('https'))) {
      return Image.network(image, height: 200, fit: BoxFit.cover);
    } else if (image is String) {
      return Image.file(File(image), height: 200, fit: BoxFit.cover);
    } else {
      return Image.asset('assets/placeholder.png', height: 200, fit: BoxFit.cover);
    }
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              icon: Icons.label,
              label: 'Name',
              value: widget.productData['name'] ?? 'No Name',
              isBold: true,
            ),
            _buildDetailRow(
              icon: Icons.branding_watermark,
              label: 'Brand',
              value: widget.productData['brand'] ?? 'No Brand',
            ),
            _buildDetailRow(
              icon: Icons.description,
              label: 'Description',
              value: widget.productData['description'] ?? 'No Description',
            ),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Price per Hour',
              value: '\$${widget.productData['pricePerHour'] ?? 0}',
            ),
            _buildDetailRow(
              icon: Icons.engineering,
              label: 'With Operator',
              value: widget.productData['withOperator'] == true ? "Yes" : "No",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerDetailsCard() {
    if (_sellerData == null) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Seller details not available.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seller Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.person,
              label: 'Name',
              value: _sellerData?['name'] ?? 'No Name',
            ),
            _buildDetailRow(
              icon: Icons.email,
              label: 'Email',
              value: _sellerData?['email'] ?? 'No Email',
            ),
            _buildDetailRow(
              icon: Icons.phone,
              label: 'Mobile',
              value: _sellerData?['mobile'] ?? 'No Mobile',
            ),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Address',
              value: _sellerData?['address'] ?? 'No Address',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
