import 'package:cloud_firestore/cloud_firestore.dart';

class PackingItem {
  final String id;
  final String name;
  final String addedBy;
  final String? checkedBy;
  final DateTime? checkedAt;

  PackingItem({
    required this.id,
    required this.name,
    required this.addedBy,
    this.checkedBy,
    this.checkedAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'addedBy': addedBy,
    'checkedBy': null,
    'checkedAt': null,
  };

  factory PackingItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackingItem(
      id: doc.id,
      name: data['name'] ?? '',
      addedBy: data['addedBy'] ?? '',
      checkedBy: data['checkedBy'],
      checkedAt: (data['checkedAt'] as Timestamp?)?.toDate(),
    );
  }
}