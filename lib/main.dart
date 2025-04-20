import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/firebase_options.dart';
import 'package:fitness_app/loginpage.dart';
import 'package:fitness_app/onboarding_screen.dart';
import 'package:fitness_app/progress_tracking_provider.dart';
import 'package:fitness_app/home.dart'; // Import HomePage
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProgressTrackingProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    setState(() {
      hasSeenOnboarding = seenOnboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If onboarding hasn't been seen, show it regardless of auth state
        if (!hasSeenOnboarding) {
          return OnboardingScreen(onFinish: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('hasSeenOnboarding', true);
            setState(() {
              hasSeenOnboarding = true;
            });
          });
        }
        
        // If user is logged in, go to home page
        if (snapshot.hasData) {
          return HomePage();
        }
        
        // Otherwise, go to login page
        return LoginPage();
      },
    );
  }
}