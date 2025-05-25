// lib/screens/classes_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../services/classes_service.dart';
import '../widgets/class_card.dart';
import 'admin_panel.dart';

class ClassesTab extends StatefulWidget {
  @override
  _ClassesTabState createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassesService _classesService = ClassesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _classesService.isUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _loadCategories() async {
    final categories = await _classesService.getCategories();
    setState(() {
      _categories = ['All', ...categories];
    });
  }

  Stream<List<FitnessClass>> _getFilteredClasses() {
    if (_selectedCategory == 'All') {
      return _classesService.getUpcomingClasses();
    } else {
      return _classesService.getClassesByCategory(_selectedCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitness Classes'),
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPanel()),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All Classes', icon: Icon(Icons.fitness_center)),
            Tab(text: 'My Classes', icon: Icon(Icons.bookmark)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllClassesTab(),
          _buildMyClassesTab(),
        ],
      ),
    );
  }

  Widget _buildAllClassesTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;

              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: Color(0xFF06402B).withOpacity(0.2),
                  checkmarkColor: Color(0xFF06402B),
                  labelStyle: TextStyle(
                    color: isSelected ? Color(0xFF06402B) : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        // Classes List
        Expanded(
          child: StreamBuilder<List<FitnessClass>>(
            stream: _getFilteredClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading classes: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final classes = snapshot.data ?? [];

              if (classes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        _selectedCategory == 'All'
                            ? 'No upcoming classes available'
                            : 'No classes available in $_selectedCategory',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return ClassCard(
                    fitnessClass: classes[index],
                    onRegister: () => _registerForClass(classes[index]),
                    onUnregister: () => _unregisterFromClass(classes[index]),
                    isRegistered: classes[index].registeredUsers.contains(_auth.currentUser?.uid),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyClassesTab() {
    return StreamBuilder<List<FitnessClass>>(
      stream: _classesService.getUserRegisteredClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading your classes: ${snapshot.error}'),
              ],
            ),
          );
        }

        final classes = snapshot.data ?? [];

        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'You haven\'t registered for any classes yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF06402B),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Browse Classes'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            return ClassCard(
              fitnessClass: classes[index],
              onRegister: () => _registerForClass(classes[index]),
              onUnregister: () => _unregisterFromClass(classes[index]),
              isRegistered: true,
              showRegisteredBadge: true,
            );
          },
        );
      },
    );
  }

  Future<void> _registerForClass(FitnessClass fitnessClass) async {
    try {
      await _classesService.registerForClass(fitnessClass.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered for ${fitnessClass.title}!'),
          backgroundColor: Color(0xFF06402B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unregisterFromClass(FitnessClass fitnessClass) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unregister from Class'),
          content: Text('Are you sure you want to unregister from ${fitnessClass.title}?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Unregister', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _classesService.unregisterFromClass(fitnessClass.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully unregistered from ${fitnessClass.title}'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}