import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  
  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    print('ProfilePage initialized with userId: ${widget.userId}');
  }

  @override
  Widget build(BuildContext context) {
    // If no userId is provided or it's empty, try to get the current user
    final String userIdToUse = widget.userId.isEmpty 
        ? FirebaseAuth.instance.currentUser?.uid ?? ''
        : widget.userId;
        
    if (userIdToUse.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You need to be logged in to view your profile'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to login page
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(userIdToUse).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading profile: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text('No profile data found for this user'),
          );
        }

        // Cast data to Map<String, dynamic>
        Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
        print('User data retrieved: ${userData.keys}');

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header with avatar
              _buildProfileHeader(userData),
              SizedBox(height: 24),

              // BMI Card
              _buildBmiCard(userData),
              SizedBox(height: 16),

              // Personal Information
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(),
                      _buildInfoRow('Name', userData['name'] ?? 'Not provided'),
                      _buildInfoRow('Email', userData['email'] ?? 'Not provided'),
                      _buildInfoRow('Age', '${userData['age'] ?? 'Not provided'}'),
                      _buildInfoRow('Gender', userData['gender'] ?? 'Not provided'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Body Measurements
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body Measurements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(),
                      _buildInfoRow('Height', '${userData['height'] ?? 'Not provided'} cm'),
                      _buildInfoRow('Weight', '${userData['weight'] ?? 'Not provided'} kg'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Sign Out Button
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: Icon(Icons.logout),
                label: Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              userData['name'] != null 
                  ? userData['name'].substring(0, 1).toUpperCase() 
                  : '?',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            userData['name'] ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userData['email'] ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard(Map<String, dynamic> userData) {
    // Calculate BMI if not provided
    double bmi = userData['bmi'] ?? _calculateBmi(userData);
    String category = _getBmiCategory(bmi);
    
    Color getBmiColor() {
      if (bmi < 18.5) return Colors.blue;
      if (bmi < 25) return Colors.green;
      if (bmi < 30) return Colors.orange;
      return Colors.red;
    }

    return Card(
      color: getBmiColor().withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'BMI Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: getBmiColor(),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: getBmiColor(),
                      ),
                    ),
                    Text(
                      _getBmiMessage(category),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBmi(Map<String, dynamic> userData) {
    try {
      if (userData.containsKey('height') && userData.containsKey('weight')) {
        double height = double.parse(userData['height'].toString()) / 100; // convert cm to m
        double weight = double.parse(userData['weight'].toString());
        return weight / (height * height);
      }
    } catch (e) {
      print('Error calculating BMI: $e');
    }
    return 0.0;
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obesity';
  }

  String _getBmiMessage(String category) {
    switch (category) {
      case 'Underweight':
        return 'Focus on gaining healthy weight';
      case 'Normal weight':
        return 'Your weight is healthy';
      case 'Overweight':
        return 'Consider a weight loss plan';
      case 'Obesity':
        return 'Please consult with a healthcare provider';
      default:
        return '';
    }
  }
}