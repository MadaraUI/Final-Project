import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'Seller/ViewOrdersScreen.dart';

class Home2Screen extends StatefulWidget {
  const Home2Screen({super.key});

  @override
  _Home2ScreenState createState() => _Home2ScreenState();
}

class _Home2ScreenState extends State<Home2Screen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController pricePerHourController = TextEditingController();
  bool withOperator = false;
  String errorMessage = '';
  bool isLoading = false;
  String? editingProductId;
  int ordersCount = 0;
  int itemsCount = 0;
  List<File?> _selectedImages = [null, null, null];

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: currentUser.uid)
          .get();

      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        ordersCount = ordersSnapshot.docs.length;
        itemsCount = productsSnapshot.docs.length;
      });
    } catch (e) {
      setState(() {
        ordersCount = 0;
        itemsCount = 0;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImages[index] = File(pickedFile.path);
      });
    }
  }

  Future<List<String>> _saveImagesLocally() async {
    List<String> imagePaths = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final imagePath = '${directory.path}/$fileName';

        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(await _selectedImages[i]!.readAsBytes());
        imagePaths.add(imagePath);
      }
    }
    return imagePaths;
  }

  Future<void> _uploadProduct() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || nameController.text.trim().isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    try {
      final localImagePaths = await _saveImagesLocally();

      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text.trim(),
        'brand': brandController.text.trim(),
        'description': descriptionController.text.trim(),
        'pricePerHour': double.tryParse(pricePerHourController.text.trim()) ?? 0,
        'withOperator': withOperator,
        'userId': currentUser.uid,
        'imagePaths': localImagePaths,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _clearFormFields();
    } catch (e) {
      errorMessage = 'Failed to upload product.';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearFormFields() {
    nameController.clear();
    brandController.clear();
    descriptionController.clear();
    pricePerHourController.clear();
    withOperator = false;
    _selectedImages = [null, null, null];
    editingProductId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editingProductId == null ? 'Upload Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopSummaryCard(),
            const SizedBox(height: 16),
            _buildTextField(nameController, 'Product Name', Icons.shopping_bag),
            const SizedBox(height: 16),
            _buildTextField(brandController, 'Brand', Icons.branding_watermark),
            const SizedBox(height: 16),
            _buildTextField(descriptionController, 'Description', Icons.description),
            const SizedBox(height: 16),
            _buildTextField(pricePerHourController, 'Price per Hour', Icons.attach_money,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildImagePickerRow(),
            const SizedBox(height: 16),
            _buildSwitch(),
            const SizedBox(height: 16),
            _buildUploadButton(),
            const SizedBox(height: 16),
            _buildUserProductsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () => _pickImage(index),
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedImages[index] == null
                ? const Center(child: Text('Tap', style: TextStyle(color: Colors.teal)))
                : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImages[index]!, fit: BoxFit.cover),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Current Orders', ordersCount),
            _buildSummaryItem('Items Count', itemsCount),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(count.toString(), style: const TextStyle(fontSize: 24, color: Colors.teal)),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('View Orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ViewOrdersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
      ),
    );
  }

  Widget _buildSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('With Operator', style: TextStyle(fontSize: 16)),
        Switch(
          value: withOperator,
          onChanged: (value) => setState(() => withOperator = value),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _uploadProduct,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: isLoading ? CircularProgressIndicator() : Text(editingProductId == null ? 'Upload' : 'Update'),
    );
  }

  Widget _buildUserProductsList() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('User not logged in'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products available.'));
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final productId = products[index].id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: product['imagePaths'] != null &&
                    (product['imagePaths'] as List).isNotEmpty
                    ? Image.file(
                  File((product['imagePaths'] as List)[0]),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.image, color: Colors.teal),
                title: Text(product['name'] ?? 'Unnamed Product'),
                subtitle: Text('Brand: ${product['brand'] ?? 'No Brand'}\n'
                    'Price per Hour: \$${product['pricePerHour'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(productId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete product.')));
    }
  }
}
