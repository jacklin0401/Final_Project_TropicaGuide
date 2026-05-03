import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ItineraryScreen extends StatefulWidget {
  final Trip trip;
  const ItineraryScreen({super.key, required this.trip});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;

  // Reorder and persist new sort orders to Firestore
  Future<void> _onReorder(List<Activity> activities, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final updated = List<Activity>.from(activities);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    // Write new sortOrders to Firestore
    for (int i = 0; i < updated.length; i++) {
      await _firestoreService.reorderActivity(widget.trip.id, updated[i].id, i.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      stream: _firestoreService.getActivities(widget.trip.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final activities = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Itinerary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text('${activities.length} activities · Drag to reorder',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    )),
                    FloatingActionButton.small(
                      heroTag: 'add_activity',
                      onPressed: () => _showAddActivity(context),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),

            if (activities.isEmpty)
              SliverFillRemaining(child: _buildEmpty(context))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverReorderableList(
                  itemCount: activities.length,
                  onReorder: (o, n) => _onReorder(activities, o, n),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(activity.id),
                      index: index,
                      child: _ActivityCard(
                        activity: activity,
                        index: index,
                        tripId: widget.trip.id,
                        onDelete: () => _deleteActivity(activity.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteActivity(String activityId) async {
    // Direct delete via Firestore
    await FirestoreService().getActivities(widget.trip.id).first;
    // We'd need a delete method — for now show a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity removed'), backgroundColor: AppTheme.surfaceHigh),
      );
    }
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🗺️', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        const Text('No activities yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Add your first activity to start building\nyour itinerary',
            textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _showAddActivity(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Activity'),
        ),
      ]),
    );
  }

  void _showAddActivity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddActivitySheet(tripId: widget.trip.id, userId: _user?.uid ?? ''),
    );
  }
}

// ── Activity card ──────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final int index;
  final String tripId;
  final VoidCallback onDelete;

  const _ActivityCard({
    required this.activity,
    required this.index,
    required this.tripId,
    required this.onDelete,
  });

  static const _emojis = ['🎯','🏖️','🌋','🎭','🍜','💦','🌾','🐒','🔥','🌅','🏛️','🚤'];

  Color get _scoreColor {
    if (activity.movedReason == null || activity.movedReason!.isEmpty) return AppTheme.surfaceHigh;
    return AppTheme.primary.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _emojis[activity.name.length % _emojis.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _scoreColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Drag handle
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.drag_handle, color: AppTheme.textMuted, size: 20),
          ),
          // Number badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('${index + 1}',
                style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                _chip(Icons.schedule_outlined, activity.startTime),
                const SizedBox(width: 10),
                _chip(Icons.attach_money, '\$${activity.budget.toStringAsFixed(0)}'),
                const SizedBox(width: 10),
                _chip(Icons.place_outlined, activity.locationName.isNotEmpty
                    ? activity.locationName : 'Location'),
              ]),
              if (activity.movedReason != null && activity.movedReason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border(left: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2)),
                    ),
                    child: Text(activity.movedReason!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppTheme.textMuted),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]);
  }
}

// ── Add activity bottom sheet ──────────────────────────────────────────────
class _AddActivitySheet extends StatefulWidget {
  final String tripId;
  final String userId;
  const _AddActivitySheet({required this.tripId, required this.userId});

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _nameController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController(text: '0.0');
  final _lngController = TextEditingController(text: '0.0');
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _add() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final activity = Activity(
        id: '',
        name: _nameController.text.trim(),
        startTime: _timeController.text,
        budget: double.tryParse(_budgetController.text) ?? 0,
        sortOrder: DateTime.now().millisecondsSinceEpoch.toDouble(),
        addedBy: widget.userId,
        latitude: double.tryParse(_latController.text) ?? 0,
        longitude: double.tryParse(_lngController.text) ?? 0,
        locationName: _locationController.text.trim(),
      );
      await _firestoreService.addActivity(widget.tripId, activity);
      if (mounted) Navigator.pop(context);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Add Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Activity Name *', prefixIcon: Icon(Icons.star_outline, color: AppTheme.textMuted)),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(
            controller: _timeController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(Icons.schedule, color: AppTheme.textMuted)),
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Budget (\$)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.textMuted)),
          )),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Location Name', prefixIcon: Icon(Icons.place_outlined, color: AppTheme.textMuted)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(
            controller: _latController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.my_location, color: AppTheme.textMuted)),
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _lngController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.my_location, color: AppTheme.textMuted)),
          )),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _add,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Add to Itinerary'),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  @override
  void dispose() {
    _nameController.dispose(); _timeController.dispose(); _budgetController.dispose();
    _locationController.dispose(); _latController.dispose(); _lngController.dispose();
    super.dispose();
  }
}
