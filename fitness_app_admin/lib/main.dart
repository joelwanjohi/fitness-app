import 'package:fitness_app_admin/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/screens/admin_login_page.dart';
import 'admin/screens/admin_dashboard_page.dart';
import 'admin/screens/user_reports_page.dart';
import 'admin/screens/meal_reports_page.dart';
import 'admin/screens/workout_reports_page.dart';
import 'admin/screens/progress_reports_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the same options as your main app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => AdminLoginPage(),
        '/dashboard': (context) => AdminDashboardPage(),
        '/users': (context) => UserReportsPage(),
        '/meals': (context) => MealReportsPage(),
        '/workouts': (context) => WorkoutReportsPage(),
        '/progress': (context) => ProgressReportsPage(),
      },
    );
  }
}

// A utility class to create the admin user
class AdminInitializer {
  static Future<void> setupInitialAdmin() async {
    try {
      // Check if admin exists first
      final adminsQuery = await FirebaseFirestore.instance
          .collection('Admins')
          .where('email', isEqualTo: 'janengugi@gmail.com')
          .get();
          
      if (adminsQuery.docs.isNotEmpty) {
        print('Admin user already exists');
        return;
      }
      
      // Create admin user in Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: "janengugi@gmail.com",
        password: "12345678",
      );
      
      // Add user to Admins collection in Firestore
      await FirebaseFirestore.instance
          .collection('Admins')
          .doc(credential.user!.uid)
          .set({
            'email': "janengugi@gmail.com",
            'name': 'Jane Ngugi',
            'role': 'admin',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
          });
          
      print('Admin user created successfully!');
    } catch (e) {
      print('Error creating admin user: $e');
    }
  }
}

// A debug widget to create the admin user - can be added to the AdminLoginPage
class CreateAdminButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await AdminInitializer.setupInitialAdmin();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin user creation attempted. Check console for results.')),
        );
      },
      child: Text('Create Admin User'),
    );
  }
}