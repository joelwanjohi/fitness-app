import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressData {
  final String localImagePath;
  final String analysis;
  final double progressScore;
  final DateTime date;
  String? firebaseId;

  ProgressData({
    required this.localImagePath,
    required this.analysis,
    required this.progressScore,
    required this.date,
    this.firebaseId,
  });

  // Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'progressScore': progressScore,
      'date': date.millisecondsSinceEpoch,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from Firestore document
  factory ProgressData.fromFirestore(DocumentSnapshot doc, {String localImagePath = ''}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProgressData(
      localImagePath: localImagePath,
      analysis: data['analysis'] ?? 'No analysis available',
      progressScore: (data['progressScore'] ?? 50).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? DateTime.now().millisecondsSinceEpoch),
      firebaseId: doc.id,
    );
  }
}

class ProgressTrackingPage extends StatefulWidget {
  const ProgressTrackingPage({Key? key}) : super(key: key);

  @override
  _ProgressTrackingPageState createState() => _ProgressTrackingPageState();
}

class _ProgressTrackingPageState extends State<ProgressTrackingPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  XFile? _pickedFile;
  List<ProgressData> _progressData = [];
  bool _isUploading = false;
  bool _isAnalyzing = false;
  bool _uploadError = false;
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _comparisonDay; // For selecting a second date to compare with
  bool _inComparisonMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadProgressData();
  }

  // Get current user ID
  String get userId => _auth.currentUser?.uid ?? '';

  // Reference to the progress collection for this user
  CollectionReference get _progressCollection {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('Users').doc(userId).collection('progress');
  }

  // Load progress data from Firestore
  Future<void> _loadProgressData() async {
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await _progressCollection
          .orderBy('date', descending: true)
          .get();
      
      List<ProgressData> data = [];
      for (var doc in querySnapshot.docs) {
        ProgressData progressEntry = ProgressData.fromFirestore(doc);
        data.add(progressEntry);
      }
      
      setState(() {
        _progressData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeAndSaveProgress() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to track progress'),
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
      // Get the selected date
      DateTime selectedDate = _selectedDay ?? DateTime.now();
      
      // Save image locally
      String fileName = 'progress_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Directory directory = await getApplicationDocumentsDirectory();
      String path = directory.path;
      String localFilePath = '$path/$fileName';
      
      // Copy the picked image to local storage
      await File(_pickedFile!.path).copy(localFilePath);

      // Get the most recent previous entry for automatic comparison
      final previousEntry = _findRecentEntryWithImage();
      
      // Run AI analysis on the image
      String analysis;
      if (previousEntry != null) {
        analysis = await _compareImages(_pickedFile!.path, previousEntry.localImagePath, previousEntry.date, previousEntry.progressScore);
      } else {
        analysis = await _analyzeImage(_pickedFile!.path);
      }
      
      final double score = _extractProgressScore(analysis);

      // Create progress data entry
      ProgressData newEntry = ProgressData(
        localImagePath: localFilePath,
        analysis: analysis,
        progressScore: score,
        date: selectedDate,
      );
      
      // Save to Firestore
      DocumentReference docRef = await _progressCollection.add(newEntry.toJson());
      newEntry.firebaseId = docRef.id;

      setState(() {
        _progressData.add(newEntry);
        _progressData.sort((a, b) => b.date.compareTo(a.date)); // Keep list sorted
        _isUploading = false;
        _isAnalyzing = false;
        _pickedFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isUploading = false;
        _isAnalyzing = false;
        _uploadError = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving progress: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Normalize date to midnight for consistent comparison
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Basic analysis for a single image
  Future<String> _analyzeImage(String imagePath) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Convert image to base64
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this fitness progress tracking image. Provide a detailed assessment of what you see. This is the first image in a progress tracking series. Give your analysis in about 3-4 sentences, focusing on key visible features. Also include a numerical progress score (from 0 to 100) on a separate line."
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

    // API endpoint
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with Gemini API: $e');
    }
  }

  // Compare current image with a previous one
  Future<String> _compareImages(String currentImagePath, String previousImagePath, DateTime previousDate, double previousScore) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Check if previous image exists
    if (!await File(previousImagePath).exists()) {
      return _analyzeImage(currentImagePath);
    }

    // Convert images to base64
    final currentImageBytes = await File(currentImagePath).readAsBytes();
    final previousImageBytes = await File(previousImagePath).readAsBytes();
    final currentBase64 = base64Encode(currentImageBytes);
    final previousBase64 = base64Encode(previousImageBytes);
    
    // Format the previous date nicely
    final previousDateStr = DateFormat('MMM d, yyyy').format(previousDate);
    
    final requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "I'm showing you two fitness progress tracking images. First is from $previousDateStr, and second is the current image. Compare these images and tell me what changes you notice. Highlight improvements or regressions. Provide your analysis in about 3-4 sentences. Also include an updated progress score (from 0 to 100) on a separate line, considering the previous score was ${previousScore.toStringAsFixed(0)}."
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": previousBase64
              }
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": currentBase64
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

    // API endpoint
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to analyze image comparison: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with Gemini API: $e');
    }
  }

  // Manual comparison between two selected dates
  Future<void> _compareSelectedDates() async {
    if (_selectedDay == null || _comparisonDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select two dates to compare'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedEntry = _getEntryForDate(_selectedDay!);
    final comparisonEntry = _getEntryForDate(_comparisonDay!);

    if (selectedEntry == null || comparisonEntry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress data not found for one or both selected dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Get comparison analysis
      final analysis = await _compareImages(
        selectedEntry.localImagePath, 
        comparisonEntry.localImagePath,
        comparisonEntry.date,
        comparisonEntry.progressScore
      );

      // Show comparison in a dialog
      setState(() {
        _isAnalyzing = false;
      });

      _showComparisonDialog(context, selectedEntry, comparisonEntry, analysis);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error comparing progress: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Find the most recent entry with a valid image
  ProgressData? _findRecentEntryWithImage() {
    for (ProgressData entry in _progressData) {
      if (entry.localImagePath.isNotEmpty) {
        final file = File(entry.localImagePath);
        if (file.existsSync()) {
          return entry;
        }
      }
    }
    return null;
  }

  // Get entry for a specific date
  ProgressData? _getEntryForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    
    for (ProgressData entry in _progressData) {
      if (_normalizeDate(entry.date) == normalizedDate) {
        return entry;
      }
    }
    return null;
  }

  // Get all entries for a specific date
  List<ProgressData> _getEntriesForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    
    return _progressData
        .where((entry) => _normalizeDate(entry.date) == normalizedDate)
        .toList();
  }

  double _extractProgressScore(String analysis) {
    // Extract score from the analysis text
    final scoreRegex = RegExp(r'(?:score|progress)(?:\s+is)?(?:\s*:)?\s*(\d+)');
    final match = scoreRegex.firstMatch(analysis);
    
    if (match != null && match.groupCount >= 1) {
      return double.tryParse(match.group(1) ?? '50') ?? 50.0;
    }
    
    return 50.0; // Default score
  }

  // Delete progress entry
  Future<void> _deleteProgressEntry(ProgressData entry) async {
    if (entry.firebaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete this entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Delete from Firestore
      await _progressCollection.doc(entry.firebaseId).delete();
      
      // Delete local image file if it exists
      if (entry.localImagePath.isNotEmpty) {
        final file = File(entry.localImagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remove from local state
      setState(() {
        _progressData.removeWhere((item) => item.firebaseId == entry.firebaseId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress entry deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting progress entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting entry: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog with comparison results
  void _showComparisonDialog(BuildContext context, ProgressData currentEntry, ProgressData previousEntry, String analysis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Progress Comparison',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(previousEntry.date),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(previousEntry.localImagePath),
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.blue),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(currentEntry.date),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(currentEntry.localImagePath),
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Analysis:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            analysis,
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildProgressScoreComparison(
                      previousEntry.progressScore, 
                      _extractProgressScore(analysis)
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get entries for selected date
    final List<ProgressData> currentDayEntries = _selectedDay != null ? 
        _getEntriesForDate(_selectedDay!) : [];

    return Scaffold(
      body: _isLoading 
      ? Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
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
                return isSameDay(_selectedDay, day) || 
                      (_comparisonDay != null && isSameDay(_comparisonDay, day));
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (_inComparisonMode) {
                    // In comparison mode, select the second date
                    if (_selectedDay != null && !isSameDay(_selectedDay, selectedDay)) {
                      _comparisonDay = selectedDay;
                    }
                  } else {
                    // Normal mode - just select the date
                    _selectedDay = selectedDay;
                    _comparisonDay = null;
                  }
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              // Custom day styling for comparison mode
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final hasEntry = _getEntriesForDate(date).isNotEmpty;
                  if (!hasEntry) return null;
                  
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  if (_comparisonDay != null && isSameDay(day, _comparisonDay)) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Comparison mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Compare dates:'),
                Switch(
                  value: _inComparisonMode,
                  onChanged: (value) {
                    setState(() {
                      _inComparisonMode = value;
                      if (!value) {
                        _comparisonDay = null;
                      }
                    });
                  },
                ),
                if (_inComparisonMode && _comparisonDay != null)
                  ElevatedButton(
                    onPressed: _compareSelectedDates,
                    child: Text('Compare'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
              ],
            ),
            
            // Selected dates information
            if (_inComparisonMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Primary: ${_selectedDay != null ? DateFormat('MMM d').format(_selectedDay!) : "Select date"}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(' vs '),
                    Text(
                      'Compare: ${_comparisonDay != null ? DateFormat('MMM d').format(_comparisonDay!) : "Select second date"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
              
            SizedBox(height: 20),
            
            // Image selection and upload section
            if (!_inComparisonMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImageFromCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isUploading || _pickedFile == null ? null : _analyzeAndSaveProgress,
                    child: _isUploading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 16),
            
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
            
            // Image preview when selected
            if (_pickedFile != null) ...[
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
            
            SizedBox(height: 20),
            
            // Progress entries for selected date
            if (_selectedDay != null) ...[
              Text(
                'Progress on ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              
              if (currentDayEntries.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Text(
                    'No progress data for this date.\nTake a photo to track your progress!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: currentDayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = currentDayEntries[index];
                    return _buildProgressCard(entry);
                  },
                ),
            ],
            
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressCard(ProgressData entry) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          FutureBuilder<bool>(
            future: File(entry.localImagePath).exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasData && snapshot.data == true) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.file(
                      File(entry.localImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              } else {
                return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    'Image no longer available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
            },
          ),
          
          // Analysis section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(entry),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  entry.analysis,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 12),
                _buildProgressScoreIndicator(entry.progressScore),
                
                // Time of entry (if available)
                if (entry.date != null) ...[
                  SizedBox(height: 12),
                  Text(
                    'Time: ${DateFormat('h:mm a').format(entry.date)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to confirm deletion
  Future<void> _showDeleteConfirmation(ProgressData entry) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Progress Entry'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text('Are you sure you want to delete this progress entry? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProgressEntry(entry);
              },
            ),
          ],
        );
      },
    );
  }
  
  // Progress score indicator widget
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${score.round()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
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
  
  // Widget for comparing progress scores
  Widget _buildProgressScoreComparison(double oldScore, double newScore) {
    final difference = newScore - oldScore;
    final isImprovement = difference > 0;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isImprovement ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Progress Change',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    'Previous',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '${oldScore.round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                isImprovement ? Icons.arrow_forward : Icons.arrow_downward,
                color: isImprovement ? Colors.green : Colors.red,
              ),
              Column(
                children: [
                  Text(
                    'Current',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '${newScore.round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            isImprovement
                ? '+${difference.abs().toStringAsFixed(1)}% Improvement'
                : '${difference.toStringAsFixed(1)}% Decrease',
            style: TextStyle(
              color: isImprovement ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}