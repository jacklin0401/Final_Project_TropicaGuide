import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class OptimizerScreen extends StatefulWidget {
  final Trip trip;
  const OptimizerScreen({super.key, required this.trip});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  final _firestoreService = FirestoreService();
  double _budgetLimit = 500;
  bool _optimizing = false;
  bool _optimized = false;

  Future<void> _runOptimizer() async {
    setState(() { _optimizing = true; _optimized = false; });
    try {
      await _firestoreService.optimizeItinerary(
        tripId: widget.trip.id,
        budgetLimit: _budgetLimit,
      );
      setState(() => _optimized = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Itinerary optimized! Scores saved.'),
            ]),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      stream: _firestoreService.getActivities(widget.trip.id),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AI Optimizer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Scores activities by time, distance & budget, then reorders',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Budget control
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceHigh),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('Budget Limit', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('\$${_budgetLimit.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppTheme.accent,
                          thumbColor: AppTheme.accent,
                          inactiveTrackColor: AppTheme.surfaceHigh,
                          overlayColor: AppTheme.accent.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _budgetLimit,
                          min: 50, max: 2000, divisions: 39,
                          onChanged: (v) => setState(() => _budgetLimit = v),
                        ),
                      ),
                      Row(children: [
                        const Text('\$50', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const Spacer(),
                        const Text('\$2,000', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Factors
                  Row(children: [
                    _factorChip('⏰ Time Windows', AppTheme.primary),
                    const SizedBox(width: 8),
                    _factorChip('📍 Distance', AppTheme.danger),
                    const SizedBox(width: 8),
                    _factorChip('💰 Budget', AppTheme.accent),
                  ]),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_optimizing || activities.isEmpty) ? null : _runOptimizer,
                      icon: _optimizing
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_optimizing ? 'Optimizing...' : _optimized ? 'Re-Optimize' : 'Optimize Itinerary'),
                    ),
                  ),

                  if (_optimized) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Activities reordered by score. Check the Itinerary tab to see the result.',
                          style: TextStyle(color: AppTheme.primary, fontSize: 13),
                        )),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text('SCORED ACTIVITIES', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                ]),
              ),
            ])),

            if (activities.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('⚡', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Add activities first', style: TextStyle(color: AppTheme.textSecondary)),
                ])),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ScoreCard(activity: activities[index], rank: index),
                    childCount: activities.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _factorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final Activity activity;
  final int rank;
  const _ScoreCard({required this.activity, required this.rank});

  Color get _rankColor => rank == 0 ? AppTheme.accent : rank == 1 ? AppTheme.textSecondary : AppTheme.textMuted;

  @override
  Widget build(BuildContext context) {
    final hasScore = activity.movedReason != null && activity.movedReason!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rank == 0 && hasScore ? AppTheme.accent.withOpacity(0.4) : AppTheme.surfaceHigh),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Rank badge
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _rankColor, width: 2),
              color: _rankColor.withOpacity(0.1),
            ),
            child: Center(child: Text('${rank + 1}',
                style: TextStyle(color: _rankColor, fontSize: 12, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(activity.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 3),
            Row(children: [
              _info(Icons.schedule, activity.startTime),
              const SizedBox(width: 12),
              _info(Icons.attach_money, '\$${activity.budget.toStringAsFixed(0)}'),
            ]),
          ])),
        ]),
        if (hasScore) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2.5)),
            ),
            child: Text(activity.movedReason!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5)),
          ),
        ],
      ]),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppTheme.textMuted),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]);
  }
}
