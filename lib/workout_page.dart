import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Timer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WorkoutPage(),
    );
  }
}

// Create a class to store body part timer preferences
class BodyPartTimerPreferences {
  static final Map<String, int> timerDurations = {
    'Chest': 60,    // Default 1 minute (60 seconds)
    'Legs': 60,     // Default 1 minute
    'Abs': 60,      // Default 1 minute
    'Shoulder': 60, // Default 1 minute
    'Neck': 60,     // Default 1 minute
  };
  
  // Map body parts to specific exercise GIF paths
  static final Map<String, String> exerciseGifs = {
    'Chest': 'assets/images/pushup.gif',
    'Legs': 'assets/images/legs.gif',
    'Abs': 'assets/images/pushup.gif',
    'Shoulder': 'assets/images/pullup.gif',
    'Neck': 'assets/images/neck.gif',
  };
}

class WorkoutPage extends StatefulWidget {
  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  double _totalCaloriesBurned = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Page'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _createBodyPartTile(context, 'Chest', Icons.accessibility),
                _createBodyPartTile(context, 'Legs', Icons.directions_walk),
                _createBodyPartTile(context, 'Abs', Icons.fitness_center),
                _createBodyPartTile(context, 'Shoulder', Icons.arrow_upward),
                _createBodyPartTile(context, 'Neck', Icons.accessibility_new),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Calories Burned',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ProgressBar(totalCaloriesBurned: _totalCaloriesBurned),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createBodyPartTile(BuildContext context, String bodyPart, IconData icon) {
    // Get the saved duration for this body part (for display purposes)
    int durationInMinutes = BodyPartTimerPreferences.timerDurations[bodyPart]! ~/ 60;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExercisePage(
              exerciseName: '$bodyPart Exercise',
              bodyPart: bodyPart, // Pass the body part
              onCaloriesBurned: (calories) {
                setState(() {
                  _totalCaloriesBurned += calories;
                });
              },
            ),
          ),
        );
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.blue,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                bodyPart,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Show the current timer setting for this body part
            Text(
              '$durationInMinutes min',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExercisePage extends StatefulWidget {
  final String exerciseName;
  final String bodyPart;
  final ValueChanged<double> onCaloriesBurned;

  ExercisePage({
    required this.exerciseName,
    required this.bodyPart,
    required this.onCaloriesBurned,
  });

  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  late int _selectedDurationInSeconds;
  bool _isRunning = false;
  double _caloriesPerSecond = 0.1;
  
  // List of duration options in minutes
  final List<int> _durationOptions = [1, 2, 3, 4, 5];
  
  @override
  void initState() {
    super.initState();
    // Initialize with the saved duration for this body part
    _selectedDurationInSeconds = BodyPartTimerPreferences.timerDurations[widget.bodyPart] ?? 60;
  }

  @override
  Widget build(BuildContext context) {
    double progress = _elapsedSeconds / _selectedDurationInSeconds;
    double caloriesBurned = _elapsedSeconds * _caloriesPerSecond;
    
    // Get the specific GIF for this body part
    String gifAsset = BodyPartTimerPreferences.exerciseGifs[widget.bodyPart] ?? 'assets/images/pushup.gif';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              gifAsset, // Use the body part specific GIF
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading GIF for ${widget.bodyPart}: $error');
                return Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 100,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'GIF not found',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Text(
            "${widget.bodyPart} Exercise",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          // Timer duration selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Set Timer (minutes): ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _selectedDurationInSeconds ~/ 60,
                onChanged: _isRunning ? null : (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedDurationInSeconds = value * 60;
                      // Save the selected duration for this body part
                      BodyPartTimerPreferences.timerDurations[widget.bodyPart] = value * 60;
                    });
                  }
                },
                items: _durationOptions.map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Timer display
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  '${_formatTime(_elapsedSeconds)} / ${_formatTime(_selectedDurationInSeconds)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 300,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          
          // Start/Stop buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? null : _startTimer,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  'Start',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(width: 30),
              ElevatedButton(
                onPressed: _isRunning ? _stopTimer : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Stop',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Calories Burned: ${caloriesBurned.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Format seconds into MM:SS
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      // Reset elapsed time if restarting
      if (_elapsedSeconds >= _selectedDurationInSeconds) {
        _elapsedSeconds = 0;
      }
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedSeconds < _selectedDurationInSeconds) {
          _elapsedSeconds++;
        } else {
          _stopTimer();
          // Call the callback with calories burned
          widget.onCaloriesBurned(_elapsedSeconds * _caloriesPerSecond);
        }
      });
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
    }
    super.dispose();
  }
}

class ProgressBar extends StatelessWidget {
  final double totalCaloriesBurned;

  const ProgressBar({Key? key, required this.totalCaloriesBurned}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = totalCaloriesBurned / 1000; // Assuming 1000 calories as the maximum goal
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totalCaloriesBurned.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 300,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.lightBlue],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}