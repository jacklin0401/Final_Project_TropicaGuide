import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip.dart';
import '../models/packing_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class PackingScreen extends StatefulWidget {
  final Trip trip;
  const PackingScreen({super.key, required this.trip});

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;
  final _addController = TextEditingController();
  bool _adding = false;

  Future<void> _checkItem(String itemId) async {
    if (_user == null) return;
    try {
      await _firestoreService.checkOffItem(widget.trip.id, itemId, _user.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(e.toString().contains('already') ? 'Already checked by someone else!' : 'Error: $e'),
            ]),
            backgroundColor: AppTheme.surfaceHigh,
          ),
        );
      }
    }
  }

  Future<void> _addItem() async {
    if (_addController.text.trim().isEmpty || _user == null) return;
    setState(() => _adding = true);
    try {
      final item = PackingItem(
        id: '',
        name: _addController.text.trim(),
        addedBy: _user.uid,
      );
      await _firestoreService.addPackingItem(widget.trip.id, item);
      _addController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PackingItem>>(
      stream: _firestoreService.getPackingList(widget.trip.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final items = snapshot.data ?? [];
        final packed = items.where((i) => i.checkedBy != null).length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Packing List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('Real-time sync · Conflict-safe check-offs',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),

                // Progress bar
                if (items.isNotEmpty) ...[
                  Row(children: [
                    const Text('Progress', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$packed / ${items.length}',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: items.isEmpty ? 0 : packed / items.length,
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceHigh,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Add item row
                Row(children: [
                  Expanded(child: TextField(
                    controller: _addController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Add item to pack...',
                      prefixIcon: Icon(Icons.add_circle_outline, color: AppTheme.textMuted),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addItem(),
                  )),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _adding ? null : _addItem,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    child: _adding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add),
                  ),
                ]),
                const SizedBox(height: 16),
              ]),
            )),

            if (items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🧳', style: TextStyle(fontSize: 52)),
                  SizedBox(height: 12),
                  Text('No items yet', style: TextStyle(color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('Add items and assign them to group members',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ])),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _PackingItemCard(
                      item: items[i],
                      currentUserId: _user?.uid ?? '',
                      onCheck: () => _checkItem(items[i].id),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }
}

class _PackingItemCard extends StatelessWidget {
  final PackingItem item;
  final String currentUserId;
  final VoidCallback onCheck;

  const _PackingItemCard({
    required this.item,
    required this.currentUserId,
    required this.onCheck,
  });

  bool get _isChecked => item.checkedBy != null;
  bool get _isMyItem => item.checkedBy == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isChecked ? AppTheme.primary.withOpacity(0.3) : AppTheme.surfaceHigh,
        ),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: _isChecked ? null : onCheck,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _isChecked ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isChecked ? AppTheme.primary : AppTheme.surfaceHigh,
                width: 2,
              ),
            ),
            child: _isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            color: _isChecked ? AppTheme.textMuted : AppTheme.textPrimary,
            decoration: _isChecked ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: _isChecked
            ? Row(children: [
                Icon(Icons.person_outline, size: 11, color: AppTheme.primary.withOpacity(0.7)),
                const SizedBox(width: 3),
                Text(
                  _isMyItem ? 'Packed by you' : 'Packed by teammate',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary),
                ),
              ])
            : Text('Added by ${item.addedBy == currentUserId ? 'you' : 'teammate'}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        trailing: !_isChecked
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
                onPressed: onCheck,
                tooltip: 'Mark as packed',
              )
            : const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
      ),
    );
  }
}
