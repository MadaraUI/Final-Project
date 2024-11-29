import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserAccountScreen extends StatefulWidget {
  const UserAccountScreen({super.key});

  @override
  _UserAccountScreenState createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends State<UserAccountScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Account')),
      body: _buildUserOrdersList(),
    );
  }

  Widget _buildUserOrdersList() {
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your orders.'));
    }

    Stream<QuerySnapshot> ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: currentUser!.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;

            // Format the order date
            String formattedDate = '';
            if (orderData['orderDate'] != null && orderData['orderDate'] is Timestamp) {
              DateTime date = (orderData['orderDate'] as Timestamp).toDate();
              formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
            }

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Product: ${orderData['productName'] ?? 'Unnamed Product'}'),
                    Text('Price per Hour: \$${orderData['pricePerHour'] ?? 0}'),
                    Text('Hours: ${orderData['hours'] ?? 'N/A'}'),
                    Text('Status: ${orderData['status'] ?? 'Unknown'}'),
                    Text('Order Date: $formattedDate'),
                    if (orderData.containsKey('rating'))
                      Text(
                        'Rating: ${orderData['rating'].toString()}',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                    const SizedBox(height: 16),
                    if (orderData['status'] == 'Completed' && !orderData.containsKey('rating'))
                      ElevatedButton(
                        onPressed: () => _addRating(context, orderId, orderData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: Text('Add Rating'),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _editOrder(context, orderId, orderData),
                          child: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _deleteOrder(orderId),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addRating(BuildContext context, String orderId, Map<String, dynamic> orderData) async {
    TextEditingController ratingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rating (1-5)',
                  hintText: 'Enter your rating',
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
                _saveRating(orderId, double.tryParse(ratingController.text) ?? 0.0);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRating(String orderId, double rating) async {
    if (rating < 1.0 || rating > 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating between 1 and 5.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'rating': rating,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $e')),
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: $e')),
      );
    }
  }

  void _editOrder(BuildContext context, String orderId, Map<String, dynamic> orderData) {
    TextEditingController hoursController = TextEditingController(text: orderData['hours'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hours'),
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
                _updateOrder(orderId, int.tryParse(hoursController.text) ?? 0);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOrder(String orderId, int newHours) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'hours': newHours,
        'status': 'Updated', // Optionally change the status when edited
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }
}
