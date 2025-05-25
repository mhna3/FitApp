// lib/screens/admin_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../services/classes_service.dart';
import 'add_edit_class.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassesService _classesService = ClassesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Manage Classes', icon: Icon(Icons.list)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageClassesTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditClassScreen(),
            ),
          );
        },
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Class'),
      ),
    );
  }

  Widget _buildManageClassesTab() {
    return StreamBuilder<List<FitnessClass>>(
      stream: _classesService.getClasses(),
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
                Icon(Icons.event_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No classes created yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditClassScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Create First Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF06402B),
                    foregroundColor: Colors.white,
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
            return _buildAdminClassCard(classes[index]);
          },
        );
      },
    );
  }

  Widget _buildAdminClassCard(FitnessClass fitnessClass) {
    final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');
    final isPastClass = !fitnessClass.isUpcoming;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fitnessClass.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06402B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Instructor: ${fitnessClass.instructor}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        dateFormatter.format(fitnessClass.dateTime),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, fitnessClass),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Status indicators
            Row(
              children: [
                _buildStatusChip(
                  '${fitnessClass.registeredUsers.length}/${fitnessClass.maxCapacity}',
                  fitnessClass.isFull ? Colors.red : Colors.green,
                  Icons.people,
                ),
                SizedBox(width: 8),
                _buildStatusChip(
                  fitnessClass.category,
                  Colors.blue,
                  Icons.category,
                ),
                SizedBox(width: 8),
                _buildStatusChip(
                  fitnessClass.difficulty,
                  Colors.orange,
                  Icons.bar_chart,
                ),
                if (isPastClass) ...[
                  SizedBox(width: 8),
                  _buildStatusChip(
                    'Past',
                    Colors.grey,
                    Icons.history,
                  ),
                ],
              ],
            ),

            if (fitnessClass.description.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                fitnessClass.description,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  fitnessClass.location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Spacer(),
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${fitnessClass.duration} min',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return StreamBuilder<List<FitnessClass>>(
      stream: _classesService.getClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06402B),
                ),
              ),
              SizedBox(height: 20),

              _buildAnalyticsCard(
                'Total Classes',
                classes.length.toString(),
                Icons.event,
                Colors.blue,
              ),

              _buildAnalyticsCard(
                'Upcoming Classes',
                classes.where((c) => c.isUpcoming).length.toString(),
                Icons.upcoming,
                Colors.green,
              ),

              _buildAnalyticsCard(
                'Total Registrations',
                classes.fold<int>(0, (sum, c) => sum + c.registeredUsers.length).toString(),
                Icons.people,
                Colors.orange,
              ),

              _buildAnalyticsCard(
                'Average Capacity Used',
                classes.isNotEmpty
                    ? '${((classes.fold<double>(0, (sum, c) => sum + (c.registeredUsers.length / c.maxCapacity)) / classes.length) * 100).toStringAsFixed(1)}%'
                    : '0%',
                Icons.analytics,
                Colors.purple,
              ),

              SizedBox(height: 20),

              Text(
                'Popular Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06402B),
                ),
              ),
              SizedBox(height: 12),

              ..._buildCategoryAnalytics(classes),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF06402B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryAnalytics(List<FitnessClass> classes) {
    final categoryCount = <String, int>{};
    for (final fitnessClass in classes) {
      categoryCount[fitnessClass.category] = (categoryCount[fitnessClass.category] ?? 0) + 1;
    }

    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      return Card(
        elevation: 2,
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFF06402B).withOpacity(0.1),
            child: Text(
              entry.value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF06402B),
              ),
            ),
          ),
          title: Text(entry.key),
          subtitle: Text('${entry.value} class${entry.value != 1 ? 'es' : ''}'),
        ),
      );
    }).toList();
  }

  void _handleMenuAction(String action, FitnessClass fitnessClass) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditClassScreen(fitnessClass: fitnessClass),
          ),
        );
        break;
      case 'duplicate':
        _duplicateClass(fitnessClass);
        break;
      case 'delete':
        _deleteClass(fitnessClass);
        break;
    }
  }

  void _duplicateClass(FitnessClass fitnessClass) {
    final duplicatedClass = fitnessClass.copyWith(
      id: '', // Will be set by Firestore
      title: '${fitnessClass.title} (Copy)',
      dateTime: fitnessClass.dateTime.add(Duration(days: 7)), // Next week
      registeredUsers: [], // Empty for new class
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditClassScreen(fitnessClass: duplicatedClass),
      ),
    );
  }

  Future<void> _deleteClass(FitnessClass fitnessClass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Class'),
        content: Text('Are you sure you want to delete "${fitnessClass.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _classesService.deleteClass(fitnessClass.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}