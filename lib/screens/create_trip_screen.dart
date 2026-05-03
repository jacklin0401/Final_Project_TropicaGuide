import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty || _destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final trip = Trip(
        id: '',
        name: _nameController.text.trim(),
        destination: _destinationController.text.trim(),
        members: [user.uid],
        createdAt: DateTime.now(),
      );
      await _firestoreService.createTrip(trip);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌴 Trip created!'), backgroundColor: AppTheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plan your adventure', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Fill in the details and invite your crew', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g. Bali Summer 2025 🌴',
                prefixIcon: Icon(Icons.luggage_outlined, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _destinationController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'e.g. Bali, Indonesia',
                prefixIcon: Icon(Icons.place_outlined, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
