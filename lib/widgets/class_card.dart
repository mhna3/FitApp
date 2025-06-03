import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';

class ClassCard extends StatelessWidget {
  final FitnessClass fitnessClass;
  final VoidCallback onRegister;
  final VoidCallback onUnregister;
  final bool isRegistered;
  final bool showRegisteredBadge;

  const ClassCard({
    Key? key,
    required this.fitnessClass,
    required this.onRegister,
    required this.onUnregister,
    this.isRegistered = false,
    this.showRegisteredBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final isPastClass = !fitnessClass.isUpcoming;

    return Card(
      elevation: 8,
      shadowColor: Color(0xFF06402B).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 125,
              decoration: BoxDecoration(
                color: _getCategoryColor().withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          color: _getCategoryColor().withOpacity(0.2),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                          ),
                        ),
                        child: fitnessClass.imageUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                          ),
                          child: Image.network(
                            fitnessClass.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getCategoryIcon(),
                                size: 48,
                                color: _getCategoryColor(),
                              );
                            },
                          ),
                        )
                            : Icon(
                          _getCategoryIcon(),
                          size: 48,
                          color: _getCategoryColor(),
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fitnessClass.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF06402B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'with ${fitnessClass.instructor}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildChip(
                                    fitnessClass.category,
                                    _getCategoryColor(),
                                  ),
                                  SizedBox(width: 8),
                                  _buildChip(
                                    fitnessClass.difficulty,
                                    _getDifficultyColor(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (fitnessClass.isFull)
                          _buildBadge('FULL', Colors.red),
                        if (showRegisteredBadge && isRegistered)
                          _buildBadge('REGISTERED', Color(0xFF06402B)),
                        if (isPastClass)
                          _buildBadge('PAST', Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fitnessClass.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        fitnessClass.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.calendar_today,
                        dateFormatter.format(fitnessClass.dateTime),
                      ),
                      SizedBox(width: 16),
                      _buildInfoItem(
                        Icons.access_time,
                        timeFormatter.format(fitnessClass.dateTime),
                      ),
                      SizedBox(width: 16),
                      _buildInfoItem(
                        Icons.timer,
                        '${fitnessClass.duration}min',
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Row(
                    children: [
                      _buildInfoItem(
                        Icons.location_on,
                        fitnessClass.location,
                      ),
                      Spacer(),
                      _buildInfoItem(
                        Icons.people,
                        '${fitnessClass.registeredUsers.length}/${fitnessClass.maxCapacity}',
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _getButtonAction(isPastClass),
                      icon: Icon(_getButtonIcon(isPastClass)),
                      label: Text(_getButtonText(isPastClass)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(isPastClass),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
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

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (fitnessClass.category.toLowerCase()) {
      case 'yoga':
        return Colors.purple;
      case 'cardio':
        return Colors.red;
      case 'strength':
        return Colors.blue;
      case 'pilates':
        return Colors.pink;
      case 'dance':
        return Colors.orange;
      case 'martial arts':
        return Colors.indigo;
      default:
        return Color(0xFF06402B);
    }
  }

  Color _getDifficultyColor() {
    switch (fitnessClass.difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (fitnessClass.category.toLowerCase()) {
      case 'yoga':
        return Icons.self_improvement;
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'pilates':
        return Icons.accessibility_new;
      case 'dance':
        return Icons.music_note;
      case 'martial arts':
        return Icons.sports_martial_arts;
      default:
        return Icons.sports_gymnastics;
    }
  }

  VoidCallback? _getButtonAction(bool isPastClass) {
    if (isPastClass) return null;
    if (fitnessClass.isFull && !isRegistered) return null;
    return isRegistered ? onUnregister : onRegister;
  }

  IconData _getButtonIcon(bool isPastClass) {
    if (isPastClass) return Icons.history;
    if (fitnessClass.isFull && !isRegistered) return Icons.block;
    return isRegistered ? Icons.cancel : Icons.add;
  }

  String _getButtonText(bool isPastClass) {
    if (isPastClass) return 'Class Completed';
    if (fitnessClass.isFull && !isRegistered) return 'Class Full';
    return isRegistered ? 'Unregister' : 'Register';
  }

  Color _getButtonColor(bool isPastClass) {
    if (isPastClass) return Colors.grey;
    if (fitnessClass.isFull && !isRegistered) return Colors.grey;
    return isRegistered ? Colors.red : Color(0xFF06402B);
  }
}