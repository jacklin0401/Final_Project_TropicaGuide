import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String startTime;
  final double budget;
  final double sortOrder;
  final String addedBy;

  Activity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.budget,
    required this.sortOrder,
    required this.addedBy,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'startTime': startTime,
    'budget': budget,
    'sortOrder': sortOrder,
    'addedBy': addedBy,
  };

  factory Activity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      name: data['name'] ?? '',
      startTime: data['startTime'] ?? '',
      budget: (data['budget'] ?? 0).toDouble(),
      sortOrder: (data['sortOrder'] ?? 0).toDouble(),
      addedBy: data['addedBy'] ?? '',
    );
  }
}