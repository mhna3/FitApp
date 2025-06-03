import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../services/classes_service.dart';
import '../widgets/class_card.dart';
import '../screens/admin_panel.dart';

class ClassesTab extends StatefulWidget {
  final int initialTab;

  const ClassesTab({Key? key, this.initialTab = 0}) : super(key: key);

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
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
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
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Classes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        actions: _isAdmin
            ? [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanel()));
            },
          ),
        ] : null,
      ),
      body: Column(
        children: [
          Material(
            color: Color(0xFF06402B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'All Classes', icon: Icon(Icons.fitness_center)),
                Tab(text: 'My Classes', icon: Icon(Icons.bookmark)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllClassesTab(),
                _buildMyClassesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllClassesTab() {
    return Column(
      children: [
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
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: Color(0xFF06402B).withOpacity(0.2),
                  checkmarkColor: Color(0xFF06402B),
                  backgroundColor: Colors.white70,
                  labelStyle: TextStyle(
                    color: isSelected ? Color(0xFF06402B) : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FitnessClass>>(
            stream: _getFilteredClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());

              if (snapshot.hasError)
                return _errorMessage('Error loading classes: ${snapshot.error}');

              final classes = snapshot.data ?? [];

              if (classes.isEmpty) {
                return _noClassesMessage(
                  _selectedCategory == 'All'
                      ? 'No upcoming classes available'
                      : 'No classes available in $_selectedCategory',
                  Icons.event_busy,
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final fitnessClass = classes[index];
                  return ClassCard(
                    fitnessClass: fitnessClass,
                    onRegister: () => _registerForClass(fitnessClass),
                    onUnregister: () => _unregisterFromClass(fitnessClass),
                    isRegistered: fitnessClass.registeredUsers.contains(_auth.currentUser?.uid),
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
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        if (snapshot.hasError)
          return _errorMessage('Error loading your classes: ${snapshot.error}');

        final classes = snapshot.data ?? [];

        if (classes.isEmpty) {
          return _noClassesMessage(
            'You haven\'t registered for any classes yet',
            Icons.event_note,
            action: ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF06402B),
                foregroundColor: Colors.white,
              ),
              child: Text('Browse Classes'),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final fitnessClass = classes[index];
            return ClassCard(
              fitnessClass: fitnessClass,
              onRegister: () => _registerForClass(fitnessClass),
              onUnregister: () => _unregisterFromClass(fitnessClass),
              isRegistered: true,
              showRegisteredBadge: true,
            );
          },
        );
      },
    );
  }

  Widget _errorMessage(String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(message),
      ],
    ),
  );

  Widget _noClassesMessage(String message, IconData icon, {Widget? action}) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          SizedBox(height: 16),
          action,
        ],
      ],
    ),
  );

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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