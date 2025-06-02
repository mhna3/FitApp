import 'package:flutter/material.dart';
import '../services/exercise_service.dart';

class ExerciseResponseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExerciseResponseCard({super.key, required this.exercise});

  @override
  State<ExerciseResponseCard> createState() => _ExerciseResponseCardState();
}

class _ExerciseResponseCardState extends State<ExerciseResponseCard> {
  final ExerciseService _exerciseService = ExerciseService();
  bool _isAdding = false;
  bool _isAdded = false;

  Future<void> _addExerciseItem() async {
    setState(() {
      _isAdding = true;
    });

    try {
      await _exerciseService.addExerciseItem(widget.exercise);

      setState(() {
        _isAdded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${widget.exercise['name']} added to your workout!'),
              ],
            ),
            backgroundColor: Color(0xFF06402B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Reset the added state after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAdded = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to add exercise: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.exercise['name']?.toString().toUpperCase() ?? 'EXERCISE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ),
                  if (widget.exercise['photo'] != null)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(widget.exercise['photo']['thumb']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
                        color: Colors.blue.shade200,
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Colors.blue[800],
                      ),
                    ),
                ],
              ),
            ),

            // Exercise information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.timer,
                    "Duration",
                    "${widget.exercise['duration_min']?.toStringAsFixed(0) ?? '0'} minutes",
                  ),
                  const Divider(),
                  _buildStatsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Row(
          children: [
            _buildStatCircle(
              "Calories",
              "${widget.exercise['nf_calories']?.toStringAsFixed(0) ?? '0'}",
              "burned",
              Colors.orange,
            ),
            _buildStatCircle(
              "Duration",
              "${widget.exercise['duration_min']?.toStringAsFixed(0) ?? '0'}",
              "minutes",
              Colors.blue,
            ),
            _buildStatCircle(
              "MET",
              "${widget.exercise['met']?.toStringAsFixed(1) ?? '0'}",
              "value",
              Colors.purple,
            ),
          ],
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: ElevatedButton.icon(
                onPressed: _isAdding || _isAdded ? null : _addExerciseItem,
                icon: _isAdding
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : _isAdded
                    ? Icon(Icons.check, color: Colors.white)
                    : Icon(Icons.add, color: Colors.white),
                label: Text(
                  _isAdding
                      ? 'Adding...'
                      : _isAdded
                      ? 'Added!'
                      : 'Add exercise',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAdded
                      ? Colors.green[600]
                      : Color(0xFF06402B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatCircle(String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}