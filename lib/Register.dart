import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  final TextEditingController customerMobileController = TextEditingController();
  final TextEditingController customerPasswordController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  final TextEditingController customerAddressController = TextEditingController();

  final TextEditingController riderNameController = TextEditingController();
  final TextEditingController riderVehicleTypeController = TextEditingController();
  final TextEditingController riderMobileController = TextEditingController();
  final TextEditingController riderEmailController = TextEditingController();
  final TextEditingController riderPasswordController = TextEditingController();
  final TextEditingController riderLocationController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text("Register"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          _buildRegistrationFormPageOne(),
          _buildRegistrationFormPageTwo(),
        ],
      ),
    );
  }

  Widget _buildRegistrationFormPageOne() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Customer Registration",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: customerEmailController,
            hintText: 'E-mail',
            icon: Icons.email,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: customerPasswordController,
            hintText: 'Password',
            icon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: customerMobileController,
            hintText: 'Mobile No',
            icon: Icons.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: customerAddressController,
            hintText: 'Permanent Address',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: _registerCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Register", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationFormPageTwo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Supplier Registration",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: riderEmailController,
            hintText: 'E-mail',
            icon: Icons.email,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: riderPasswordController,
            hintText: 'Password',
            icon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: riderNameController,
            hintText: 'Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: riderVehicleTypeController,
            hintText: 'Vehicle Type',
            icon: Icons.directions_car,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: riderMobileController,
            hintText: 'Mobile No',
            icon: Icons.phone,
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: _registerRider,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Register", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  void _registerCustomer() async {
    String email = customerEmailController.text;
    String password = customerPasswordController.text;
    String mobile = customerMobileController.text;
    String address = customerAddressController.text;

    if (email.isNotEmpty && password.isNotEmpty && mobile.isNotEmpty && address.isNotEmpty) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'mobile': mobile,
          'address': address,
          'role': 'Customer',
        });

        _showDialog('Registration Successful', 'Your registration has been successful.');
      } catch (e) {
        _showDialog('Error', e.toString());
      }
    } else {
      _showDialog('Error', 'Please fill all the fields.');
    }
  }

  void _registerRider() async {
    String email = riderEmailController.text;
    String password = riderPasswordController.text;
    String name = riderNameController.text;
    String vehicleType = riderVehicleTypeController.text;
    String mobile = riderMobileController.text;

    if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty && vehicleType.isNotEmpty && mobile.isNotEmpty) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'vehicleType': vehicleType,
          'mobile': mobile,
          'role': 'Supplier',
        });

        _showDialog('Registration Successful', 'Your registration has been successful.');
      } catch (e) {
        _showDialog('Error', e.toString());
      }
    } else {
      _showDialog('Error', 'Please fill all the fields.');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
