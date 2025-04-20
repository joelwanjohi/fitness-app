// lib/shared/error_handler.dart
import 'package:flutter/material.dart';

class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  static String getReadableFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found': return 'No user found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'This email is already registered';
      default: return 'An error occurred: $errorCode';
    }
  }
}