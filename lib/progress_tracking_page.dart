import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Load environment variables before the app starts
Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Load environment variables
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progress Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ProgressTrackingPage(),
    );
  }
}

class ProgressData {
  final String imagePath;
  final String analysis;
  final double progressScore;
  final DateTime date;

  ProgressData({
    required this.imagePath,
    required this.analysis,
    required this.progressScore,
    required this.date,
  });

  // Useful for debugging
  @override
  String toString() {
    return 'ProgressData(date: $date, score: $progressScore, analysis: $analysis)';
  }
}

class ProgressTrackingPage extends StatefulWidget {
  const ProgressTrackingPage({Key? key}) : super(key: key);

  @override
  _ProgressTrackingPageState createState() => _ProgressTrackingPageState();
}

class _ProgressTrackingPageState extends State<ProgressTrackingPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile;
  Map<DateTime, ProgressData> _progressData = {};
  bool _isUploading = false;
  bool _isAnalyzing = false;
  bool _uploadError = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Track whether we're doing the first image analysis or comparing with previous images
  bool get _hasHistoricalData => _progressData.isNotEmpty;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      // Handle error
    }
  }

  Future<void> _uploadAndAnalyzeImage() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isAnalyzing = true;
      _uploadError = false;
    });

    try {
      // Get the directory for storing files on the device
      Directory directory = await getApplicationDocumentsDirectory();
      String path = directory.path;

      // Create a unique file name for the image
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      String filePath = '$path/$fileName';

      // Copy the picked image to the local file path
      await File(_pickedFile!.path).copy(filePath);

      // Run AI analysis on the image
      final String analysis = await _analyzeImage(filePath);
      final double score = _extractProgressScore(analysis);
      
      // Calculate current day with time set to midnight for consistent key lookup
      DateTime normalizedDay = _normalizeDate(_selectedDay ?? DateTime.now());

      setState(() {
        _progressData[normalizedDay] = ProgressData(
          imagePath: filePath,
          analysis: analysis,
          progressScore: score,
          date: normalizedDay,
        );
        _isUploading = false;
        _isAnalyzing = false;
      });
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isUploading = false;
        _isAnalyzing = false;
        _uploadError = true;
      });
    }
  }

  // Normalize date to midnight for consistent mapping
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<String> _analyzeImage(String imagePath) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Convert image to base64
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Prepare request body based on whether we have historical data
    final requestBody = _hasHistoricalData
        ? await _prepareComparisonRequest(base64Image)
        : _prepareInitialRequest(base64Image);

    // Create API endpoint URL
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Extract the text from Gemini's response
        final String analysis = data['candidates'][0]['content']['parts'][0]['text'];
        return analysis;
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with Gemini API: $e');
    }
  }

  Map<String, dynamic> _prepareInitialRequest(String base64Image) {
    return {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this progress tracking image. Provide a detailed assessment of what you see. This is the first image in a progress tracking series. Give your analysis in about 3-4 sentences, focusing on key visible features. Also include a numerical progress score (from 0 to 100) on a separate line."
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 32,
        "topP": 0.95,
        "maxOutputTokens": 512,
      }
    };
  }

  Future<Map<String, dynamic>> _prepareComparisonRequest(String base64Image) async {
    // Find the most recent previous image to compare with
    final latestEntry = _findMostRecentEntry();
    
    if (latestEntry == null) {
      return _prepareInitialRequest(base64Image);
    }
    
    // Convert previous image to base64
    final previousImageBytes = await File(latestEntry.imagePath).readAsBytes();
    final previousBase64Image = base64Encode(previousImageBytes);
    
    // Format the previous date nicely
    final previousDateStr = DateFormat('MMM d, yyyy').format(latestEntry.date);
    
    return {
      "contents": [
        {
          "parts": [
            {
              "text": "I'm showing you two progress tracking images. First is from $previousDateStr, and second is the current image. Compare these images and tell me what changes you notice. Highlight improvements or regressions. Provide your analysis in about 3-4 sentences. Also include an updated progress score (from 0 to 100) on a separate line, considering the previous score was ${latestEntry.progressScore.toStringAsFixed(0)}."
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": previousBase64Image
              }
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 32,
        "topP": 0.95,
        "maxOutputTokens": 512,
      }
    };
  }

  ProgressData? _findMostRecentEntry() {
    if (_progressData.isEmpty) return null;
    
    DateTime mostRecent = _progressData.keys.first;
    for (final date in _progressData.keys) {
      if (date.isAfter(mostRecent) && date.isBefore(_selectedDay ?? DateTime.now())) {
        mostRecent = date;
      }
    }
    
    // If we only have future entries (which doesn't make sense logically)
    // or all entries are on the currently selected day, return null
    if (mostRecent.isAfter(_selectedDay ?? DateTime.now())) {
      return null;
    }
    
    return _progressData[mostRecent];
  }

  double _extractProgressScore(String analysis) {
    // Try to extract a score from the analysis text
    final scoreRegex = RegExp(r'(?:score|progress)(?:\s+is)?(?:\s*:)?\s*(\d+)');
    final match = scoreRegex.firstMatch(analysis);
    
    if (match != null && match.groupCount >= 1) {
      return double.tryParse(match.group(1) ?? '50') ?? 50.0;
    }
    
    // If no score found, default to 50
    return 50.0;
  }

  @override
  Widget build(BuildContext context) {
    // Get the current day's progress data if available
    final DateTime normalizedSelectedDay = _normalizeDate(_selectedDay ?? DateTime.now());
    final ProgressData? currentDayData = _progressData[normalizedSelectedDay];

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Tracking'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Calendar with event markers
            TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              // Event markers for days with progress data
              eventLoader: (day) {
                // Normalize the day to match our keys
                final normalizedDay = _normalizeDate(day);
                return _progressData.containsKey(normalizedDay) ? ['progress'] : [];
              },
              calendarStyle: CalendarStyle(
                // Custom marker style for days with progress data
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Image selection and upload section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: Icon(Icons.photo),
                  label: Text('Select Image'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadAndAnalyzeImage,
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isAnalyzing ? 'Analyzing...' : 'Upload & Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            // Error message if upload fails
            if (_uploadError)
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error processing image. Please try again.',
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            
            // Progress analysis display for the selected day
            if (currentDayData != null) ...[
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      currentDayData.analysis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 15),
                    _buildProgressScoreIndicator(currentDayData.progressScore),
                  ],
                ),
              ),
              
              // Display the image for the selected day
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(currentDayData.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            
            // If we have a picked file but haven't uploaded yet, show a preview
            if (currentDayData == null && _pickedFile != null) ...[
              SizedBox(height: 20),
              Text(
                'Image Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_pickedFile!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            
            // If no data for selected day and no picked file, show a message
            if (currentDayData == null && _pickedFile == null && _selectedDay != null) ...[
              SizedBox(height: 40),
              Icon(
                Icons.photo_library_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 10),
              Text(
                'No progress data for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Select an image to track your progress',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressScoreIndicator(double score) {
    Color progressColor;
    if (score < 30) {
      progressColor = Colors.red;
    } else if (score < 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Score:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${score.round()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade200,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score / 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: progressColor,
                gradient: LinearGradient(
                  colors: [
                    progressColor.withOpacity(0.7),
                    progressColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}