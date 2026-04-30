import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String name;
  final String destination;
  final List<String> members;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.members,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'destination': destination,
    'members': members,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Trip.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      name: data['name'] ?? '',
      destination: data['destination'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}