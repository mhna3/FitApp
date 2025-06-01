import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/login.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Personal Information"),
            _buildEditableField("Email", 'email'),
            _buildEditableField("Age", "age"),
            _buildEditableField("Height", "height"),
            _buildEditableField("Weight", "weight"),

            SizedBox(height: 24),

            _buildSectionHeader("Fitness Goals"),
            _buildEditableField("Daily Calorie Goal", "2000"),
            _buildEditableField("Target Weight", "60 kg"),
            _buildEditableField("Workout Days per Week", "3"),
            _buildEditableField("Daily Step Goal", "10,000"),

            SizedBox(height: 32),
            Divider(thickness: 1.2),
            SizedBox(height: 12),

            Center(
              child: ElevatedButton.icon(
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
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text("Logout", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF06402B),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )
          ),
          SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              contentPadding: EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
