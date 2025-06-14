import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/login.dart';
import '../services/exercise_service.dart';
import '../services/food_service.dart';
import '../services/nutritionix_api.dart';
import '../widgets/exercise_response_card.dart';
import '../widgets/food_response_card.dart';
import 'classes_tab.dart';
import '../screens/profile_page.dart';

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
  final api = NutritionixApi(appId: 'a', appKey: 'a');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  int _currentIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUser = _auth.currentUser;

    _pages.addAll([
      NaturalNutrientsTab(api: api),
      ExerciseTab(api: api),
      ClassesTab(),
      ProfilePage(),
    ]);
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
      backgroundColor: Color(0xFFF5F5F5),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Color(0xFF06402B),
            unselectedItemColor: Colors.grey[600],
            backgroundColor: Colors.grey[50],
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.restaurant_menu, 0),
                label: 'Nutrients',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.fitness_center, 1),
                label: 'Exercise',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.event, 2),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person, 3),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;

    return Container(
      decoration: isSelected
          ? BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF06402B).withOpacity(0.2),
      ) : null,
      padding: EdgeInsets.all(8),
      child: Icon(
        icon,
        color: isSelected ? Color(0xFF06402B) : Colors.grey[600],
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
  final FoodService _foodService = FoodService();
  bool _loading = false;
  bool _loadingAddedItems = true;
  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _todaysAddedItems = [];

  @override
  void initState() {
    super.initState();
    _loadTodaysItems();
  }

  Future<void> _loadTodaysItems() async {
    try {
      setState(() {
        _loadingAddedItems = true;
      });

      final items = await _foodService.getTodaysFoodItems();

      if (mounted) {
        setState(() {
          _todaysAddedItems = items;
          _loadingAddedItems = false;
        });
      }
    } catch (e) {
      print('Error loading today\'s items: $e');
      if (mounted) {
        setState(() {
          _loadingAddedItems = false;
        });
      }
    }
  }

  Future<void> _query() async {
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

  Future<void> _deleteItem(String itemId) async {
    try {
      await _foodService.deleteFoodItem(itemId);
      await _loadTodaysItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item removed from your intake'),
            backgroundColor: Color(0xFF06402B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrients',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadTodaysItems,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
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
              child: _foods.isEmpty && _todaysAddedItems.isEmpty
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
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_todaysAddedItems.isNotEmpty) ...[
                      _buildSectionHeader("Today's Added Items", _todaysAddedItems.length),
                      SizedBox(height: 8),
                      ..._todaysAddedItems.map((item) => _buildAddedItemCard(item)),
                      SizedBox(height: 24),
                    ],

                    if (_foods.isNotEmpty) ...[
                      _buildSectionHeader("Search Results", _foods.length),
                      SizedBox(height: 8),
                      ..._foods.map((food) => FoodResponseCard(food: food)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06402B),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF06402B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedItemCard(Map<String, dynamic> item) {
    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Item"),
            content: Text("Are you sure you want to delete this food item?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Delete")),
            ],
          ),
        );
        if (shouldDelete == true) {
          _showDeleteConfirmation(item);
          return true;
        }
        return false;
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child:SizedBox( height: 100,
          child:
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: item['photoUrl'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['photoUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.fastfood, color: Colors.green.shade700);
                      },
                    ),
                  )
                      : Icon(Icons.fastfood, color: Colors.green.shade700),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),
                            Text(
                              capitalize(item['foodName'] ?? 'Unknown Food'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF06402B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${item['servingQty']} ${item['servingUnit']}",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 12),
                          _buildNutrientChip("${item['calories']?.toStringAsFixed(0) ?? '0'} cal", Colors.orange),
                          SizedBox(height: 6),
                          _buildNutrientChip("${item['protein']?.toStringAsFixed(1) ?? '0'}g protein", Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Item'),
          content: Text('Remove "${item['foodName']}" from today\'s intake?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(item['id']);
              },
            ),
          ],
        );
      },
    );
  }
  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class ExerciseTab extends StatefulWidget {
  final NutritionixApi api;
  ExerciseTab({required this.api});

  @override
  _ExerciseTabState createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab> {
  final _controller = TextEditingController();
  final ExerciseService _exerciseService = ExerciseService();
  bool _loading = false;
  bool _loadingAddedItems = true;
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _todaysAddedExercises = [];

  @override
  void initState() {
    super.initState();
    _loadTodaysExercises();
  }

  Future<void> _loadTodaysExercises() async {
    try {
      setState(() {
        _loadingAddedItems = true;
      });

      final items = await _exerciseService.getTodaysExerciseItems();

      if (mounted) {
        setState(() {
          _todaysAddedExercises = items;
          _loadingAddedItems = false;
        });
      }
    } catch (e) {
      print('Error loading today\'s exercises: $e');
      if (mounted) {
        setState(() {
          _loadingAddedItems = false;
        });
      }
    }
  }

  Future<void> _calculate() async {
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

  Future<void> _deleteExercise(String itemId) async {
    try {
      await _exerciseService.deleteExerciseItem(itemId);
      await _loadTodaysExercises();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exercise removed from your workout'),
            backgroundColor: Color(0xFF06402B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove exercise: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadTodaysExercises,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
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
              child: _exercises.isEmpty && _todaysAddedExercises.isEmpty
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
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_todaysAddedExercises.isNotEmpty) ...[
                      _buildSectionHeader("Today's Workout", _todaysAddedExercises.length),
                      SizedBox(height: 8),
                      ..._todaysAddedExercises.map((exercise) => _buildAddedExerciseCard(exercise)),
                      SizedBox(height: 24),
                    ],

                    if (_exercises.isNotEmpty) ...[
                      _buildSectionHeader("Search Results", _exercises.length),
                      SizedBox(height: 8),
                      ..._exercises.map((exercise) => ExerciseResponseCard(exercise: exercise)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06402B),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFF06402B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedExerciseCard(Map<String, dynamic> exercise) {
    return Dismissible(
        key: Key(exercise['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Delete Item"),
              content: Text("Are you sure you want to delete this exercise?"),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Delete")),
              ],
            ),
          );
          if (shouldDelete == true) {
            _showDeleteConfirmation(exercise);
            return true;
          }
          return false;
        },
    child: Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
         SizedBox(
            height: 100,
           child:
         Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      capitalize(exercise['exerciseName'] ?? 'Unknown Exercise'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF06402B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      "${exercise['duration']} minutes",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    ],
                ),
              ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(height: 12),
                        _buildExerciseChip("${exercise['calories']?.toStringAsFixed(0) ?? '0'} cal", Colors.orange),
                        SizedBox(height: 6),
                        _buildExerciseChip("${exercise['duration']?.toStringAsFixed(0) ?? '0'} min", Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
          ),
        ),
    ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildExerciseChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Exercise'),
          content: Text('Remove "${exercise['exerciseName']}" from today\'s workout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExercise(exercise['id']);
              },
            ),
          ],
        );
      },
    );
  }
}