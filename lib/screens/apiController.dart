import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/login.dart';
import '../services/nutritionix_api.dart';
import '../widgets/exercise_response_card.dart';
import '../widgets/food_response_card.dart';
import 'classes_tab.dart';

class NutritionixApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutritionix GUI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final api = NutritionixApi(appId: 'appId', appKey: 'appKey');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;

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

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Color(0xFF06402B),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Logout'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _signOut();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fit App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (currentUser != null)
              Text(
                'Welcome, ${currentUser!.displayName ?? currentUser!.email}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Nutrients',
              icon: Icon(Icons.restaurant_menu),
            ),
            Tab(
              text: 'Exercise',
              icon: Icon(Icons.fitness_center),
            ),
            Tab(
              text: 'Classes',
              icon: Icon(Icons.event),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NaturalNutrientsTab(api: api),
          ExerciseTab(api: api),
          ClassesTab(), // Added the new ClassesTab
        ],
      ),
    );
  }
}

class NaturalNutrientsTab extends StatefulWidget {
  final NutritionixApi api;
  NaturalNutrientsTab({required this.api});

  @override
  _NaturalNutrientsTabState createState() => _NaturalNutrientsTabState();
}

class _NaturalNutrientsTabState extends State<NaturalNutrientsTab> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _foods = [];

  _query() async {
    setState(() {
      _loading = true;
      _foods = [];
    });

    try {
      final data = await widget.api.naturalNutrients(_controller.text);
      setState(() {
        _foods = List<Map<String, dynamic>>.from(data['foods']);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'e.g. 1 cup rice and 2 boiled eggs',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
              ),
              prefixIcon: Icon(Icons.food_bank, color: Color(0xFF06402B)),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
              filled: true,
              fillColor: Colors.green.shade50,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _query,
            icon: _loading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(Icons.search),
            label: Text(_loading ? 'Searching...' : 'Get Nutrients'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF06402B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _foods.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Enter a food description to get results",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _foods.length,
              itemBuilder: (context, index) {
                return FoodResponseCard(food: _foods[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseTab extends StatefulWidget {
  final NutritionixApi api;
  ExerciseTab({required this.api});
  @override _ExerciseTabState createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _exercises = [];

  _calculate() async {
    setState(() {
      _loading = true;
      _exercises = [];
    });

    try {
      final data = await widget.api.naturalExercise(
        _controller.text,
        gender: 'male',
        weightKg: 70,
        heightCm: 175,
        age: 25,
      );
      setState(() {
        _exercises = List<Map<String, dynamic>>.from(data['exercises']);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'e.g. 30 minutes cycling',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
              ),
              prefixIcon: Icon(Icons.fitness_center, color: Color(0xFF06402B)),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
              filled: true,
              fillColor: Colors.green.shade50,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _calculate,
            icon: _loading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(Icons.calculate),
            label: Text(_loading ? 'Calculating...' : 'Calculate Calories'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF06402B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _exercises.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Enter an exercise and press the button",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                return ExerciseResponseCard(exercise: _exercises[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}