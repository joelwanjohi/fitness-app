import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/admin_routes.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  // Flag for showing the admin initialization button (for development only)
  final bool _showAdminInitButton = false; 

  @override
  void initState() {
    super.initState();
    // Pre-fill the admin credentials for development
    _emailController.text = "janengugi@gmail.com";
    _passwordController.text = "12345678";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Attempt to sign in
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (credential.user != null) {
          // Check if user has admin role
          final userDoc = await FirebaseFirestore.instance
              .collection('Admins')
              .doc(credential.user!.uid)
              .get();

          if (userDoc.exists) {
            // User is an admin, navigate to dashboard
            
            // Update last login timestamp
            await FirebaseFirestore.instance
                .collection('Admins')
                .doc(credential.user!.uid)
                .update({
              'lastLogin': DateTime.now().millisecondsSinceEpoch,
            });
            
            if (!mounted) return;
            AdminRoutes.navigateToDashboard(context);
          } else {
            // Not an admin, sign out and show error
            await FirebaseAuth.instance.signOut();
            setState(() {
              _errorMessage = 'You do not have admin privileges';
              _isLoading = false;
            });
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found with this email';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        } else {
          message = 'Authentication failed: ${e.message}';
        }
        
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Helper to create admin user during development
  Future<void> _createAdminUser() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Check if admin already exists
      final adminsQuery = await FirebaseFirestore.instance
          .collection('Admins')
          .where('email', isEqualTo: 'janengugi@gmail.com')
          .get();
          
      if (adminsQuery.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'Admin user already exists';
          _isLoading = false;
        });
        return;
      }
      
      // Create admin user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'janengugi@gmail.com',
        password: '12345678',
      );
      
      // Add to Admins collection
      await FirebaseFirestore.instance
          .collection('Admins')
          .doc(credential.user!.uid)
          .set({
            'email': 'janengugi@gmail.com',
            'name': 'Jane Ngugi',
            'role': 'admin',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
          });
          
      setState(() {
        _isLoading = false;
        _errorMessage = 'Admin user created successfully!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error creating admin: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Icon
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.blue,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Admin Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Login to access the admin panel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter admin email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter admin password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: _errorMessage.contains('successfully') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                
                // Admin creation button (only shown during development)
                if (_showAdminInitButton) ...[
                  const SizedBox(height: 24),
                  
                  OutlinedButton(
                    onPressed: _isLoading ? null : _createAdminUser,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Initialize Admin User'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}