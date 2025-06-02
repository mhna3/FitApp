import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/screens/login.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  User? currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for form fields
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _calorieGoalController;
  late TextEditingController _caloriesBurnedGoalController;  // NEW: Calories out goal
  late TextEditingController _targetWeightController;
  late TextEditingController _workoutDaysController;
  late TextEditingController _stepGoalController;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _initializeControllers();
    _loadUserProfile();
  }

  void _initializeControllers() {
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _calorieGoalController = TextEditingController();
    _caloriesBurnedGoalController = TextEditingController();  // NEW
    _targetWeightController = TextEditingController();
    _workoutDaysController = TextEditingController();
    _stepGoalController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calorieGoalController.dispose();
    _caloriesBurnedGoalController.dispose();  // NEW
    _targetWeightController.dispose();
    _workoutDaysController.dispose();
    _stepGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await _userService.getUserProfile();

      if (profile != null && mounted) {
        setState(() {
          _emailController.text = currentUser?.email ?? '';
          _ageController.text = profile['age']?.toString() ?? '';
          _heightController.text = profile['height']?.toString() ?? '';
          _weightController.text = profile['weight']?.toString() ?? '';
          _calorieGoalController.text = profile['dailyCalorieGoal']?.toString() ?? '2000';
          _caloriesBurnedGoalController.text = profile['dailyCaloriesBurnedGoal']?.toString() ?? '300';  // NEW
          _targetWeightController.text = profile['targetWeight']?.toString() ?? '';
          _workoutDaysController.text = profile['workoutDaysPerWeek']?.toString() ?? '3';
          _stepGoalController.text = profile['dailyStepGoal']?.toString() ?? '10000';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare profile data
      final profileData = {
        'email': _emailController.text.trim(),
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'dailyCalorieGoal': _calorieGoalController.text.trim(),
        'dailyCaloriesBurnedGoal': _caloriesBurnedGoalController.text.trim(),  // NEW
        'targetWeight': _targetWeightController.text.trim(),
        'workoutDaysPerWeek': _workoutDaysController.text.trim(),
        'dailyStepGoal': _stepGoalController.text.trim(),
      };

      // Save to Firestore
      final success = await _userService.saveUserProfile(profileData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile saved successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF06402B),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Calculate and show BMI if available
        final bmi = await _userService.calculateBMI();
        if (bmi != null && mounted) {
          _showBMIDialog(bmi);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showBMIDialog(double bmi) {
    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = Colors.blue;
    } else if (bmi < 25) {
      category = 'Normal weight';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = Colors.orange;
    } else {
      category = 'Obese';
      color = Colors.red;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: color),
            SizedBox(width: 8),
            Text('Your BMI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              category,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'BMI is calculated as weight(kg) / height(m)²',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(Icons.save),
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF06402B)),
            SizedBox(height: 16),
            Text('Loading your profile...'),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Personal Information"),
              _buildEditableField(
                "Email",
                _emailController,
                icon: Icons.email,
                enabled: false, // Email can't be changed here
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Age",
                _ageController,
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isNotEmpty == true) {
                    final age = int.tryParse(value!);
                    if (age == null || age < 13 || age > 120) {
                      return 'Please enter a valid age (13-120)';
                    }
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Height (cm)",
                _heightController,
                icon: Icons.height,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isNotEmpty == true) {
                    final height = double.tryParse(value!.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (height == null || height < 100 || height > 250) {
                      return 'Please enter a valid height (100-250 cm)';
                    }
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Weight (kg)",
                _weightController,
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isNotEmpty == true) {
                    final weight = double.tryParse(value!.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (weight == null || weight < 30 || weight > 300) {
                      return 'Please enter a valid weight (30-300 kg)';
                    }
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              _buildSectionHeader("Fitness Goals"),
              _buildEditableField(
                "Daily Calorie Goal (Intake)",
                _calorieGoalController,
                icon: Icons.local_fire_department,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Calorie goal is required';
                  }
                  final calories = int.tryParse(value!);
                  if (calories == null || calories < 1000 || calories > 5000) {
                    return 'Please enter a valid calorie goal (1000-5000)';
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Daily Calories Burned Goal",  // NEW FIELD
                _caloriesBurnedGoalController,
                icon: Icons.whatshot,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Calories burned goal is required';
                  }
                  final calories = int.tryParse(value!);
                  if (calories == null || calories < 100 || calories > 2000) {
                    return 'Please enter a valid calories burned goal (100-2000)';
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Target Weight (kg)",
                _targetWeightController,
                icon: Icons.flag,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isNotEmpty == true) {
                    final weight = double.tryParse(value!.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (weight == null || weight < 30 || weight > 300) {
                      return 'Please enter a valid target weight (30-300 kg)';
                    }
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Workout Days per Week",
                _workoutDaysController,
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Workout days is required';
                  }
                  final days = int.tryParse(value!);
                  if (days == null || days < 0 || days > 7) {
                    return 'Please enter a valid number of days (0-7)';
                  }
                  return null;
                },
              ),
              _buildEditableField(
                "Daily Step Goal",
                _stepGoalController,
                icon: Icons.directions_walk,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Step goal is required';
                  }
                  final steps = int.tryParse(value!);
                  if (steps == null || steps < 1000 || steps > 50000) {
                    return 'Please enter a valid step goal (1000-50000)';
                  }
                  return null;
                },
              ),

              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF06402B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),
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

  Widget _buildEditableField(
      String label,
      TextEditingController controller, {
        IconData? icon,
        TextInputType? keyboardType,
        bool enabled = true,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              fillColor: enabled ? Colors.white : Colors.grey[200],
              filled: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              prefixIcon: icon != null
                  ? Icon(icon, color: enabled ? Color(0xFF06402B) : Colors.grey)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}