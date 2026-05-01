import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/packing_item.dart';
import '../models/user_profile.dart';
import 'itinerary_optimizer.dart';

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

  Future<void> reorderActivity(
    String tripId,
    String activityId,
    double newSortOrder,
  ) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('activities')
        .doc(activityId)
        .update({'sortOrder': newSortOrder});
  }


  // OPTIMIZER
  Future<void> optimizeItinerary({
    required String tripId,
    required double budgetLimit,
  }) async {
    final snapshot = await _db
        .collection('trips')
        .doc(tripId)
        .collection('activities')
        .get();

    final activities =
        snapshot.docs.map((doc) => Activity.fromDoc(doc)).toList();

    final optimizer = ItineraryOptimizer();

    final results = optimizer.optimize(
      activities: activities,
      budgetLimit: budgetLimit,
    );

    await applyOptimizedOrder(tripId, results);
  }

  Future<void> applyOptimizedOrder(
    String tripId,
    List<OptimizerResult> results,
  ) async {
    final batch = _db.batch();

    for (int i = 0; i < results.length; i++) {
      final docRef = _db
          .collection('trips')
          .doc(tripId)
          .collection('activities')
          .doc(results[i].activity.id);

      batch.update(docRef, {
        'sortOrder': i.toDouble(),
        'movedReason': results[i].reason,
        'optimizerScore': results[i].score,
      });
    }

    await batch.commit();
  }

  // Packing List

  Future<void> addPackingItem(String tripId, PackingItem item) async {
    await _db
        .collection('trips')
        .doc(tripId)
        .collection('packingList')
        .add(item.toMap());
  }

  Future<void> checkOffItem(
    String tripId,
    String itemId,
    String userId,
  ) async {
    final ref = _db
        .collection('trips')
        .doc(tripId)
        .collection('packingList')
        .doc(itemId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Item not found');
      }

      final data = snapshot.data();
      final checkedBy = data?['checkedBy'];

      if (checkedBy != null && checkedBy.toString().isNotEmpty) {
        return;
      }

      transaction.update(ref, {
        'isChecked': true,
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
        .map((snap) =>
            snap.docs.map((doc) => PackingItem.fromDoc(doc)).toList());
  }

  // User Profiles

  Future<void> createUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.id).set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(userId).update(data);
  }
}