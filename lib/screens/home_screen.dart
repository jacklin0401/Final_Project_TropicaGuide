import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0EA5E9)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('🌴', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          const Text('TropicaGuide'),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: Text(
                (_user?.displayName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
            color: AppTheme.surface,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'signout',
                child: Row(children: [
                  const Icon(Icons.logout, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Text(_user?.displayName ?? 'Sign Out',
                      style: const TextStyle(color: AppTheme.textPrimary)),
                ]),
              ),
            ],
            onSelected: (v) async {
              if (v == 'signout') {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false);
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _user == null
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<List<Trip>>(
              stream: _firestoreService.getUserTrips(_user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                final trips = snapshot.data ?? [];
                if (trips.isEmpty) return _buildEmpty();
                return _buildTripList(trips);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateTripScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏝️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('No trips yet!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Create your first trip and invite your crew to start planning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateTripScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Create a Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(List<Trip> trips) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hey, ${_user?.displayName?.split(' ').first ?? 'Traveler'}! 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Where to next?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        const SizedBox(height: 24),
        const Text('YOUR TRIPS', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: AppTheme.textMuted, letterSpacing: 1.5,
        )),
        const SizedBox(height: 12),
        ...trips.map((trip) => _TripCard(trip: trip)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  static const _emojis = ['🏝️', '🌋', '🗺️', '⛵', '🌅', '🎭'];

  @override
  Widget build(BuildContext context) {
    final emoji = _emojis[trip.name.length % _emojis.length];
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceHigh),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.3), const Color(0xFF0EA5E9).withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.name, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(trip.destination, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.group_outlined, size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('${trip.members.length} traveler${trip.members.length != 1 ? 's' : ''}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ],
            )),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ]),
        ),
      ),
    );
  }
}
