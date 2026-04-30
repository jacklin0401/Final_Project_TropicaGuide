import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/packing_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Trips
  Future<String> createTrip(Trip trip) async {
    final ref = await _db.collection('trips').add(trip.toMap());
    return ref.id;
  }

  Stream<List<Trip>> getUserTrips(String userId) {
    return _db
        .collection('trips')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Trip.fromDoc(doc)).toList());
  }

  // Activities
  Future<void> addActivity(String tripId, Activity activity) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('activities')
        .add(activity.toMap());
  }

  Stream<List<Activity>> getActivities(String tripId) {
    return _db
        .collection('trips')
        .doc(tripId)
        .collection('activities')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Activity.fromDoc(doc)).toList());
  }

  Future<void> reorderActivity(String tripId, String activityId, double newSortOrder) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('activities')
        .doc(activityId)
        .update({'sortOrder': newSortOrder});
  }

  // Packing List
  Future<void> addPackingItem(String tripId, PackingItem item) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('packingList')
        .add(item.toMap());
  }

  Future<void> checkOffItem(String tripId, String itemId, String userId) async {
    final ref = _db
        .collection('trips')
        .doc(tripId)
        .collection('packingList')
        .doc(itemId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw Exception('Item not found');
      if (snapshot.data()!['checkedBy'] != null) return;
      transaction.update(ref, {
        'checkedBy': userId,
        'checkedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<PackingItem>> getPackingList(String tripId) {
    return _db
        .collection('trips')
        .doc(tripId)
        .collection('packingList')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PackingItem.fromDoc(doc)).toList());
  }
}