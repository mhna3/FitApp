import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../services/classes_service.dart';

class AddEditClassScreen extends StatefulWidget {
  final FitnessClass? fitnessClass;

  const AddEditClassScreen({Key? key, this.fitnessClass}) : super(key: key);

  @override
  _AddEditClassScreenState createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClassesService _classesService = ClassesService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructorController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlController;
  late TextEditingController _maxCapacityController;
  late TextEditingController _durationController;

  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 9, minute: 0);
  String _selectedCategory = 'Yoga';
  String _selectedDifficulty = 'Beginner';

  bool _isLoading = false;
  bool get _isEditing => widget.fitnessClass != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _instructorController = TextEditingController();
    _locationController = TextEditingController();
    _imageUrlController = TextEditingController();
    _maxCapacityController = TextEditingController(text: '20');
    _durationController = TextEditingController(text: '60');
  }

  void _loadInitialData() {
    if (_isEditing) {
      final fitnessClass = widget.fitnessClass!;
      _titleController.text = fitnessClass.title;
      _descriptionController.text = fitnessClass.description;
      _instructorController.text = fitnessClass.instructor;
      _locationController.text = fitnessClass.location;
      _imageUrlController.text = fitnessClass.imageUrl;
      _maxCapacityController.text = fitnessClass.maxCapacity.toString();
      _durationController.text = fitnessClass.duration.toString();
      _selectedDate = fitnessClass.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(fitnessClass.dateTime);
      _selectedCategory = fitnessClass.category;
      _selectedDifficulty = fitnessClass.difficulty;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _maxCapacityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Class' : 'Add New Class'),
        backgroundColor: Color(0xFF06402B),
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteClass,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Information'),
              SizedBox(height: 16),

              _buildTextField(
                controller: _titleController,
                label: 'Class Title',
                icon: Icons.title,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter a class title';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              _buildTextField(
                controller: _instructorController,
                label: 'Instructor Name',
                icon: Icons.person,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter instructor name';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),
              _buildSectionHeader('Class Details'),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      items: ['Yoga', 'Cardio', 'Strength', 'Pilates', 'Dance', 'Martial Arts'],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Difficulty',
                      value: _selectedDifficulty,
                      items: ['Beginner', 'Intermediate', 'Advanced'],
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _durationController,
                      label: 'Duration (minutes)',
                      icon: Icons.timer,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter duration';
                        }
                        final duration = int.tryParse(value!);
                        if (duration == null || duration <= 0) {
                          return 'Please enter a valid duration';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxCapacityController,
                      label: 'Max Capacity',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter capacity';
                        }
                        final capacity = int.tryParse(value!);
                        if (capacity == null || capacity <= 0) {
                          return 'Please enter a valid capacity';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),
              _buildSectionHeader('Schedule & Location'),
              SizedBox(height: 16),

              _buildDateTimePickers(),

              SizedBox(height: 16),

              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                icon: Icons.image,
              ),

              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveClass,
                  icon: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : _isEditing
                        ? 'Update Class'
                        : 'Create Class',
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF06402B),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF06402B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF06402B),
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF06402B), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimePickers() {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Color(0xFF06402B)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        dateFormatter.format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: _selectTime,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Color(0xFF06402B)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        timeFormatter.format(DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        )),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF06402B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF06402B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final classDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final fitnessClass = FitnessClass(
        id: _isEditing ? widget.fitnessClass!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim(),
        dateTime: classDateTime,
        duration: int.parse(_durationController.text),
        maxCapacity: int.parse(_maxCapacityController.text),
        registeredUsers: _isEditing ? widget.fitnessClass!.registeredUsers : [],
        location: _locationController.text.trim(),
        difficulty: _selectedDifficulty,
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim(),
        createdAt: _isEditing ? widget.fitnessClass!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        await _classesService.updateClass(fitnessClass);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class updated successfully!'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
      } else {
        await _classesService.addClass(fitnessClass);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class created successfully!'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Class'),
        content: Text('Are you sure you want to delete this class? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700]),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _isEditing) {
      try {
        await _classesService.deleteClass(widget.fitnessClass!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Color(0xFF06402B),
          ),
        );
        Navigator.pop(context);
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