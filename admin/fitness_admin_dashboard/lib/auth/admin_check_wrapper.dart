import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/dashboard/dashboard_page.dart';
import 'login_page.dart';

class AdminCheckWrapper extends StatelessWidget {
  const AdminCheckWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return LoginPage();
        }
        
        // Check if user is admin
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              final isAdmin = userData?['isAdmin'] == true;
              
              if (isAdmin) {
                return AdminDashboardPage();
              } else {
                // Not an admin - show access denied
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Access Denied'),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 80, color: Colors.red),
                        SizedBox(height: 24),
                        Text(
                          'Admin Access Denied',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'You do not have administrator privileges.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text('Go Back', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            
            return Scaffold(
              body: Center(
                child: Text('Error loading user data'),
              ),
            );
          },
        );
      },
    );
  }
}