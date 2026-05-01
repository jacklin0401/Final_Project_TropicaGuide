import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadActivityImage({
    required File imageFile,
    required String tripId,
    required String activityId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = _storage
        .ref()
        .child('trips')
        .child(tripId)
        .child('activities')
        .child(activityId)
        .child(fileName);

    final uploadTask = await ref.putFile(imageFile);

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<String> uploadTripImage({
    required File imageFile,
    required String tripId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = _storage
        .ref()
        .child('trips')
        .child(tripId)
        .child('cover')
        .child(fileName);

    final uploadTask = await ref.putFile(imageFile);

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    final ref = _storage.refFromURL(imageUrl);
    await ref.delete();
  }
}