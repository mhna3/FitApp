import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/login.dart';
import '../services/nutritionix_api.dart';
import '../widgets/exercise_response_card.dart';
import '../widgets/food_response_card.dart';
import 'classes_tab.dart';
import '../screens/profile_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../screens/settings.dart';



class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  List<Exercise> sampleExercises = [
    Exercise(name: "Jumping Jacks", duration: 10, calories: 80),
    Exercise(name: "Plank", duration: 5, calories: 40),
    Exercise(name: "Push-ups", duration: 15, calories: 120),
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 2 to 3
    currentUser = _auth.currentUser;

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            IconButton(onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())); }, icon: Icon(Icons.settings, color: Colors.white,))
          ],
        ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 24),
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
                    ), SizedBox(width: 12),
                    Text("Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF06402B))),
                    ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGoalProgress("Strength", 0.7, ),
                        _buildGoalProgress("Calories/goal", 0.5, ),
                        _buildGoalProgress("Steps", 0.9, ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.event, color: Colors.green[700]),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text("Next Class: Zumba"),
                        Text("Today at 6:00 PM", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
            SizedBox(height: 24),
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
                          "Total Nutrients",
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
                        _buildNutrientProgress("Protein", 0.7, ),
                        _buildNutrientProgress("Carbs", 0.5, ),
                        _buildNutrientProgress("Fat", 0.9, ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),
            _buildExerciseSummary(sampleExercises),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Widget _buildGoalProgress(String label, double percent) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if(percent<0.5)
         CircularPercentIndicator(
          radius: 40.0,
          lineWidth: 6.0,
          percent: percent,
          center: Text("${(percent * 100).toInt()}%"),
          progressColor: Colors.red,
          backgroundColor: Colors.grey.shade300,
          animation: true,
         ),
        if(percent>=0.5 && percent<0.7)
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 6.0,
            percent: percent,
            center: Text("${(percent * 100).toInt()}%"),
            progressColor: Colors.orange,
            backgroundColor: Colors.grey.shade300,
            animation: true,
          ),

        if(percent>=0.7)
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 6.0,
            percent: percent,
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

Widget _buildNutrientProgress(String label, double amount) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if(label=='Protein')
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 6.0,
            center: Text("${amount.toInt()}"),
            progressColor: Colors.purple,
            backgroundColor: Colors.grey.shade300,
            animation: true,
          ),
        if(label == 'Carbs')
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 6.0,
            center: Text("${amount.toInt()}"),
            progressColor: Colors.blue,
            backgroundColor: Colors.grey.shade300,
            animation: true,
          ),
        if(label == 'Fat')
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 6.0,
            center: Text("${amount.toInt()}"),
            progressColor: Colors.red,
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

Widget _buildExerciseSummary(List<Exercise> exercises) {
  int totalCalories = exercises.fold(0, (sum, e) => sum + e.calories);
  int totalMinutes = exercises.fold(0, (sum, e) => sum + e.duration);

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
                backgroundColor: Colors.green[100],
                child: Icon(Icons.sports_gymnastics, color: Colors.green[700]),
              ),
              SizedBox(width: 12),
              Text("Exercise Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF06402B))),
            ],
          ),
          SizedBox(height: 8),
          Text("Total Duration: $totalMinutes minutes"),
          Text("Total Calories Burned: $totalCalories cal"),
          SizedBox(height: 12),
          Column(
            children: exercises.take(3).map((e) => ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text(e.name),
              subtitle: Text("${e.duration} min • ${e.calories} cal"),
            )).toList(),
          )
        ],
      ),
    ),
  );
}

class Exercise {
  final String name;
  final int duration;
  final int calories;

  Exercise({required this.name, required this.duration, required this.calories});
}


