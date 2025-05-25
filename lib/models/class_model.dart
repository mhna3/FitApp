// lib/models/class_model.dart
class FitnessClass {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final DateTime dateTime;
  final int duration; // in minutes
  final int maxCapacity;
  final List<String> registeredUsers;
  final String location;
  final String difficulty; // Beginner, Intermediate, Advanced
  final String category; // Yoga, Cardio, Strength, etc.
  final String imageUrl;
  final DateTime createdAt;
  final bool isActive;

  FitnessClass({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.dateTime,
    required this.duration,
    required this.maxCapacity,
    required this.registeredUsers,
    required this.location,
    required this.difficulty,
    required this.category,
    this.imageUrl = '',
    required this.createdAt,
    this.isActive = true,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'duration': duration,
      'maxCapacity': maxCapacity,
      'registeredUsers': registeredUsers,
      'location': location,
      'difficulty': difficulty,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  // Create from Firestore Map
  factory FitnessClass.fromMap(Map<String, dynamic> map) {
    return FitnessClass(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructor: map['instructor'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] ?? 0),
      duration: map['duration'] ?? 0,
      maxCapacity: map['maxCapacity'] ?? 0,
      registeredUsers: List<String>.from(map['registeredUsers'] ?? []),
      location: map['location'] ?? '',
      difficulty: map['difficulty'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }

  // Getters for computed properties
  bool get isFull => registeredUsers.length >= maxCapacity;
  int get availableSpots => maxCapacity - registeredUsers.length;
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool Function(Object? element) get isUserRegistered => registeredUsers.contains;

  // Copy with method for updates
  FitnessClass copyWith({
    String? id,
    String? title,
    String? description,
    String? instructor,
    DateTime? dateTime,
    int? duration,
    int? maxCapacity,
    List<String>? registeredUsers,
    String? location,
    String? difficulty,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return FitnessClass(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      location: location ?? this.location,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}