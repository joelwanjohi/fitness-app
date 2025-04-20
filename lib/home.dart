import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/profile.dart';
import 'package:fitness_app/signuppage.dart';
import 'meal_page.dart';
import 'progress_tracking_page.dart';
import 'workout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String get userId => _auth.currentUser?.uid ?? '';
  
  // List of pages to display based on bottom navigation
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    // Initialize pages array with the current user ID
    _pages = [
      HomeContent(),  // Main home content
      MealPage(),     // Meal tracking page
      WorkoutPage(),  // Workout tracking page
      ProgressTrackingPage(), // Progress tracking page
      ProfilePage(userId: userId), // Profile page with current user ID
    ];
    
    // Debug - print the current user ID
    print('Current user in HomePage: ${userId.isEmpty ? "Not logged in" : userId}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle back button press to prevent automatic logout
      onWillPop: () async {
        // If we're not on the main page (index 0), go back to it instead of exiting
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false; // Don't allow the default back button behavior
        }
        // Show confirmation dialog when on main page
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Fitness App'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Meal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Workout',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          UserProfileSection(),
          QuickActionsSection(
            onMealTap: () {
              final homeState = context.findAncestorStateOfType<_HomePageState>();
              if (homeState != null) {
                homeState._onItemTapped(1);
              }
            },
            onWorkoutTap: () {
              final homeState = context.findAncestorStateOfType<_HomePageState>();
              if (homeState != null) {
                homeState._onItemTapped(2);
              }
            },
            onProgressTap: () {
              final homeState = context.findAncestorStateOfType<_HomePageState>();
              if (homeState != null) {
                homeState._onItemTapped(3);
              }
            },
          ),
          DailyProgressSection(),
          RecentActivitySection(),
        ],
      ),
    );
  }
}

class UserProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),
                LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              final homeState = context.findAncestorStateOfType<_HomePageState>();
              if (homeState != null) {
                homeState._onItemTapped(4); // Navigate to profile page
              }
            },
          ),
        ],
      ),
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onMealTap;
  final VoidCallback onWorkoutTap;
  final VoidCallback onProgressTap;

  const QuickActionsSection({
    Key? key,
    required this.onMealTap,
    required this.onWorkoutTap,
    required this.onProgressTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionButton(
            icon: Icons.restaurant,
            label: 'Track Meal',
            onPressed: onMealTap,
          ),
          ActionButton(
            icon: Icons.fitness_center,
            label: 'Start Workout',
            onPressed: onWorkoutTap,
          ),
          ActionButton(
            icon: Icons.camera_alt,
            label: 'Upload Progress',
            onPressed: onProgressTap,
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          iconSize: 36.0,
          onPressed: onPressed,
        ),
        SizedBox(height: 8.0),
        Text(label),
      ],
    );
  }
}

class DailyProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16.0),
            Text(
              'Daily Progress',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Calories Burned'),
                    SizedBox(height: 8.0),
                    CircularProgressIndicator(
                      value: 0.7,
                      strokeWidth: 15,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Protein Intake'),
                    SizedBox(height: 8.0),
                    CircularProgressIndicator(
                      value: 0.4,
                      strokeWidth: 15,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 18.0),
          ],
        ),
      ),
    );
  }
}

class RecentActivitySection extends StatefulWidget {
  @override
  _RecentActivitySectionState createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  
  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
  }
  
  Future<void> _loadRecentActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get meals
      final mealQuery = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('mealPlans')
          .orderBy('dateAdded', descending: true)
          .limit(3)
          .get();
      
      // Get workouts (assuming you have a workouts collection)
      final workoutQuery = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('workouts')
          .orderBy('dateAdded', descending: true)
          .limit(3)
          .get();
      
      // Get progress photos (assuming you have a progress collection)
      final progressQuery = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('progress')
          .orderBy('dateAdded', descending: true)
          .limit(3)
          .get();
      
      // Combine all activities
      List<Map<String, dynamic>> allActivities = [];
      
      // Add meals
      for (var doc in mealQuery.docs) {
        Map<String, dynamic> data = doc.data();
        allActivities.add({
          'id': doc.id,
          'type': 'meal',
          'title': data['name'] ?? 'Meal',
          'subtitle': 'Calories: ${data['calories']?.toStringAsFixed(0) ?? '0'}, Protein: ${data['protein']?.toStringAsFixed(1) ?? '0'}g',
          'date': DateTime.fromMillisecondsSinceEpoch(data['dateAdded'] ?? 0),
        });
      }
      
      // Add workouts
      for (var doc in workoutQuery.docs) {
        Map<String, dynamic> data = doc.data();
        allActivities.add({
          'id': doc.id,
          'type': 'workout',
          'title': data['name'] ?? 'Workout',
          'subtitle': data['description'] ?? 'Workout session',
          'date': DateTime.fromMillisecondsSinceEpoch(data['dateAdded'] ?? 0),
        });
      }
      
      // Add progress entries
      for (var doc in progressQuery.docs) {
        Map<String, dynamic> data = doc.data();
        allActivities.add({
          'id': doc.id,
          'type': 'progress',
          'title': 'Progress Update',
          'subtitle': data['description'] ?? 'Progress tracking',
          'date': DateTime.fromMillisecondsSinceEpoch(data['dateAdded'] ?? 0),
          'showPhoto': data['photoUrl'] != null,
          'photoUrl': data['photoUrl'],
        });
      }
      
      // Sort all activities by date
      allActivities.sort((a, b) {
        DateTime dateA = a['date'];
        DateTime dateB = b['date'];
        return dateB.compareTo(dateA); // Descending order (newest first)
      });
      
      // Take the 5 most recent activities
      setState(() {
        _activities = allActivities.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent activities: $e');
      setState(() {
        _isLoading = false;
        // If error occurs, provide fallback data
        _activities = [
          {
            'id': 'fallback1',
            'type': 'meal',
            'title': 'Breakfast',
            'subtitle': 'No data available',
            'date': DateTime.now(),
          },
          {
            'id': 'fallback2',
            'type': 'workout',
            'title': 'Workout',
            'subtitle': 'No data available',
            'date': DateTime.now().subtract(Duration(days: 1)),
          }
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadRecentActivities,
              ),
            ],
          ),
          SizedBox(height: 8.0),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            )
          else if (_activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No recent activities found.\nStart tracking meals, workouts, or progress!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            Column(
              children: _activities.map((activity) {
                // Format the date
                String formattedDate = _formatDate(activity['date']);
                
                // Get icon based on activity type
                IconData activityIcon = _getActivityIcon(activity['type']);
                
                return ActivityTile(
                  title: activity['title'],
                  subtitle: activity['subtitle'],
                  date: formattedDate,
                  icon: activityIcon,
                  showPhoto: activity['showPhoto'] ?? false,
                  photoUrl: activity['photoUrl'],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);
    
    if (activityDate == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (activityDate == yesterday) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'meal':
        return Icons.restaurant;
      case 'workout':
        return Icons.fitness_center;
      case 'progress':
        return Icons.timeline;
      default:
        return Icons.event_note;
    }
  }
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final IconData icon;
  final bool showPhoto;
  final String? photoUrl;

  ActivityTile({
    required this.title,
    required this.subtitle,
    required this.date,
    this.icon = Icons.event_note,
    this.showPhoto = false,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: showPhoto && photoUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(photoUrl!),
              backgroundColor: Colors.grey[200],
            )
          : CircleAvatar(
              backgroundColor: _getColorForIcon(icon),
              child: Icon(icon, color: Colors.white),
            ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          date,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Color _getColorForIcon(IconData icon) {
    if (icon == Icons.restaurant) return Colors.green;
    if (icon == Icons.fitness_center) return Colors.orange;
    if (icon == Icons.timeline) return Colors.blue;
    return Colors.grey;
  }
}