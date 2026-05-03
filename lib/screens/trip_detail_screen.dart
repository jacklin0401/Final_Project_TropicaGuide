import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../theme/app_theme.dart';
import 'itinerary_screen.dart';
import 'optimizer_screen.dart';
import 'packing_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    ItineraryScreen(trip: widget.trip),
    OptimizerScreen(trip: widget.trip),
    PackingScreen(trip: widget.trip),
  ];

  static const _tabs = [
    {'label': 'Itinerary', 'icon': Icons.map_outlined, 'activeIcon': Icons.map},
    {'label': 'Optimizer', 'icon': Icons.auto_awesome_outlined, 'activeIcon': Icons.auto_awesome},
    {'label': 'Packing', 'icon': Icons.backpack_outlined, 'activeIcon': Icons.backpack},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(widget.trip.destination,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Live', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.surfaceHigh)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _tabs.map((tab) => BottomNavigationBarItem(
            icon: Icon(tab['icon'] as IconData),
            activeIcon: Icon(tab['activeIcon'] as IconData),
            label: tab['label'] as String,
          )).toList(),
        ),
      ),
    );
  }
}
