import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewOrdersScreen extends StatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  _ViewOrdersScreenState createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends State<ViewOrdersScreen> {
  final String currentSellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Orders'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: currentSellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders available.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final buyerId = orderData['buyerId'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${orderData['orderId'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Product: ${orderData['productName'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Price: \$${orderData['price'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Hours: ${orderData['hours'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(buyerId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                return const Text('Buyer details not available');
                              }

                              final buyerData = snapshot.data!.data() as Map<String, dynamic>;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Buyer: ${buyerData['name'] ?? 'No Name'}'),
                                  Text('Email: ${buyerData['email'] ?? 'No Email'}'),
                                  Text('Mobile: ${buyerData['mobile'] ?? 'No Mobile'}'),
                                ],
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Add functionality to contact the buyer
                            },
                            icon: const Icon(Icons.contact_phone),
                            label: const Text('Contact Buyer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Order Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: orderData['status'] ?? 'Not decided',
                        onChanged: (String? newValue) {
                          _updateOrderStatus(orders[index].id, newValue);
                        },
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'Not decided', child: Text('Not decided')),
                          DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String? status) async {
    if (status != null) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
    }
  }
}
