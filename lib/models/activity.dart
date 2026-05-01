import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String startTime;
  final double budget;
  final double sortOrder;
  final String addedBy;

  final double latitude;
  final double longitude;
  final String locationName;

  final String? movedReason;

  Activity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.budget,
    required this.sortOrder,
    required this.addedBy,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.movedReason,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'startTime': startTime,
        'budget': budget,
        'sortOrder': sortOrder,
        'addedBy': addedBy,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'movedReason': movedReason ?? '',
        'createdAt': FieldValue.serverTimestamp(),
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
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      locationName: data['locationName'] ?? '',
      movedReason: data['movedReason'] ?? '',
    );
  }
}