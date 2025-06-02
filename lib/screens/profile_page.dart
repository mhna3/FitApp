import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/login.dart';
import '../services/nutritionix_api.dart';
import '../services/food_service.dart';
import '../services/exercise_service.dart';
import '../services/classes_service.dart';
import '../models/class_model.dart';
import '../widgets/exercise_response_card.dart';
import '../widgets/food_response_card.dart';
import 'classes_tab.dart';
import '../screens/profile_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../screens/settings.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodService _foodService = FoodService();
  final ExerciseService _exerciseService = ExerciseService();
  final ClassesService _classesService = ClassesService();
  User? currentUser;

  Map<String, double> _todaysNutrients = {};
  Map<String, double> _goalProgress = {};
  Map<String, double> _exerciseStats = {};
  Map<String, double> _exerciseProgress = {};
  Map<String, double> _foodGoals = {};
  Map<String, double> _exerciseGoals = {};
  List<Map<String, dynamic>> _recentExercises = [];
  FitnessClass? _nextClass;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUser = _auth.currentUser;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load nutrition data
      final nutrients = await _foodService.getTodaysNutrients();
      final progress = await _foodService.calculateGoalProgress(nutrients);
      final foodGoals = await _foodService.getUserGoals();

      // Load exercise data
      final exerciseStats = await _exerciseService.getTodaysExerciseStats();
      final exerciseProgress = await _exerciseService.calculateExerciseProgress(exerciseStats);
      final exerciseGoals = await _exerciseService.getUserExerciseGoals();
      final recentExercises = await _exerciseService.getRecentExercises();

      // Load next class
      final nextClass = await _getNextUpcomingClass();

      if (mounted) {
        setState(() {
          _todaysNutrients = nutrients;
          _goalProgress = progress;
          _exerciseStats = exerciseStats;
          _exerciseProgress = exerciseProgress;
          _foodGoals = foodGoals;
          _exerciseGoals = exerciseGoals;
          _recentExercises = recentExercises;
          _nextClass = nextClass;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<FitnessClass?> _getNextUpcomingClass() async {
    try {
      final classesStream = _classesService.getUserRegisteredClasses();
      final classes = await classesStream.first;

      final now = DateTime.now();
      final upcomingClasses = classes.where((c) => c.dateTime.isAfter(now)).toList();

      if (upcomingClasses.isNotEmpty) {
        upcomingClasses.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return upcomingClasses.first;
      }

      return null;
    } catch (e) {
      print('Error getting next class: $e');
      return null;
    }
  }

  Future<void> _refreshData() async {
    await _loadAllData();
  }

  void _navigateToMyClasses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassesTabWithTab(initialTab: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentUser != null)
              Text(
                'Welcome, ${currentUser!.displayName ?? currentUser!.email}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
            icon: Icon(Icons.settings, color: Colors.white),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 24),

              // Daily Goals Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.track_changes, color: Colors.green[700]),
                          ),
                          SizedBox(width: 12),
                          Text("Daily Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF06402B))),
                          Spacer(),
                          if (_isLoading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildGoalProgress("Calories In", _goalProgress['calories'] ?? 0.0),
                          _buildGoalProgress("Calories Out", _exerciseProgress['caloriesBurned'] ?? 0.0),
                          _buildGoalProgress("Exercise", _exerciseProgress['exercises'] ?? 0.0),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_todaysNutrients.isNotEmpty || _exerciseStats.isNotEmpty)
                        _buildQuickStats(),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Next Class Card - Now Dynamic and Clickable
              _buildNextClassCard(),

              SizedBox(height: 24),

              // Detailed Nutrients Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.eco, color: Colors.green[700]),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Today's Nutrients",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06402B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientProgress("Protein", _todaysNutrients['protein'] ?? 0.0, Colors.purple),
                          _buildNutrientProgress("Carbs", _todaysNutrients['carbs'] ?? 0.0, Colors.blue),
                          _buildNutrientProgress("Fat", _todaysNutrients['fat'] ?? 0.0, Colors.red),
                        ],
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
              _buildExerciseSummary(_recentExercises),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextClassCard() {
    return InkWell(
      onTap: _navigateToMyClasses,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _nextClass != null ? Colors.blue[100] : Colors.grey[100],
                child: Icon(
                  Icons.event,
                  color: _nextClass != null ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nextClass != null
                          ? "Next Class: ${_nextClass!.title}"
                          : "No Upcoming Classes",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF06402B),
                      ),
                    ),
                    SizedBox(height: 4),
                    if (_nextClass != null) ...[
                      Text(
                        _formatClassDateTime(_nextClass!.dateTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "with ${_nextClass!.instructor} • ${_nextClass!.location}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ] else
                      Text(
                        "Tap to browse and register for classes",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _nextClass != null ? Colors.blue[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _nextClass != null ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatClassDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return "Today at ${DateFormat('HH:mm').format(dateTime)}";
    } else if (difference.inDays == 1) {
      return "Tomorrow at ${DateFormat('HH:mm').format(dateTime)}";
    } else if (difference.inDays < 7) {
      return "${DateFormat('EEEE').format(dateTime)} at ${DateFormat('HH:mm').format(dateTime)}";
    } else {
      return "${DateFormat('MMM dd').format(dateTime)} at ${DateFormat('HH:mm').format(dateTime)}";
    }
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Text(
            "Today's Summary",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF06402B),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  "Eaten",
                  "${(_todaysNutrients['calories'] ?? 0).toInt()}",
                  "${(_foodGoals['calories'] ?? 2000).toInt()} cal"
              ),
              _buildStatItem(
                  "Burned",
                  "${(_exerciseStats['calories'] ?? 0).toInt()}",
                  "${(_exerciseGoals['caloriesBurned'] ?? 300).toInt()} cal"
              ),
              _buildStatItem(
                  "Net",
                  "${((_todaysNutrients['calories'] ?? 0) - (_exerciseStats['calories'] ?? 0)).toInt()}",
                  "cal"
              ),
              _buildStatItem(
                  "Exercises",
                  "${(_exerciseStats['exercises'] ?? 0).toInt()}",
                  "${(_exerciseGoals['exercises'] ?? 3).toInt()}"
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String goal) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        if (goal.isNotEmpty && !goal.endsWith('cal') && goal != value)
          Text("/ $goal", style: TextStyle(fontSize: 12, color: Colors.grey[600]))
        else if (goal.isNotEmpty && goal.endsWith('cal'))
          Text("/ $goal", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildGoalProgress(String label, double percent) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (percent < 0.5)
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 6.0,
              percent: percent.clamp(0.0, 1.0),
              center: Text("${(percent * 100).toInt()}%"),
              progressColor: Colors.red,
              backgroundColor: Colors.grey.shade300,
              animation: true,
            ),
          if (percent >= 0.5 && percent < 0.7)
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 6.0,
              percent: percent.clamp(0.0, 1.0),
              center: Text("${(percent * 100).toInt()}%"),
              progressColor: Colors.orange,
              backgroundColor: Colors.grey.shade300,
              animation: true,
            ),
          if (percent >= 0.7)
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 6.0,
              percent: percent.clamp(0.0, 1.0),
              center: Text("${(percent * 100).toInt()}%"),
              progressColor: Colors.green,
              backgroundColor: Colors.grey.shade300,
              animation: true,
            ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientProgress(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 6.0,
            percent: 0.75, // This could be calculated based on goals
            center: Text("${amount.toStringAsFixed(0)}g"),
            progressColor: color,
            backgroundColor: Colors.grey.shade300,
            animation: true,
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSummary(List<Map<String, dynamic>> exercises) {
    final totalCalories = _exerciseStats['calories']?.toInt() ?? 0;
    final totalMinutes = _exerciseStats['duration']?.toInt() ?? 0;
    final totalExercises = exercises.length;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.sports_gymnastics, color: Colors.blue[700]),
                ),
                SizedBox(width: 12),
                Text("Exercise Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF06402B))),
              ],
            ),
            SizedBox(height: 8),
            Text("Total Duration: $totalMinutes minutes"),
            Text("Total Calories Burned: $totalCalories cal"),
            Text("Exercises Completed: $totalExercises"),
            SizedBox(height: 12),
            if (exercises.isNotEmpty)
              Column(
                children: exercises.take(3).map((e) => ListTile(
                  leading: Icon(Icons.fitness_center, color: Colors.blue[700]),
                  title: Text(e['exerciseName'] ?? 'Exercise'),
                  subtitle: Text("${e['duration']?.toInt() ?? 0} min • ${e['calories']?.toInt() ?? 0} cal"),
                  dense: true,
                )).toList(),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    "No exercises completed today",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Create a wrapper for ClassesTab that allows setting initial tab
class ClassesTabWithTab extends StatelessWidget {
  final int initialTab;

  const ClassesTabWithTab({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClassesTabPage(initialTab: initialTab);
  }
}

class Exercise {
  final String name;
  final int duration;
  final int calories;

  Exercise({required this.name, required this.duration, required this.calories});
}