import 'dart:math';
import '../models/activity.dart';

class OptimizerResult {
  final Activity activity;
  final double score;
  final String reason;

  OptimizerResult({
    required this.activity,
    required this.score,
    required this.reason,
  });
}

class ItineraryOptimizer {
  List<OptimizerResult> optimize({
    required List<Activity> activities,
    required double budgetLimit,
  }) {
    if (activities.isEmpty) return [];

    final List<OptimizerResult> results = [];

    Activity? previousActivity;

    for (final activity in activities) {
      double score = 0;
      final List<String> reasons = [];

      // Budget scoring
      if (activity.budget <= budgetLimit * 0.25) {
        score += 40;
        reasons.add('low cost');
      } else if (activity.budget <= budgetLimit * 0.50) {
        score += 25;
        reasons.add('moderate cost');
      } else if (activity.budget <= budgetLimit) {
        score += 10;
        reasons.add('within budget');
      } else {
        score -= 30;
        reasons.add('over budget');
      }

      // Time window scoring
      final hour = _parseHour(activity.startTime);

      if (hour >= 8 && hour < 12) {
        score += 30;
        reasons.add('morning activity');
      } else if (hour >= 12 && hour < 17) {
        score += 20;
        reasons.add('afternoon activity');
      } else if (hour >= 17 && hour < 21) {
        score += 10;
        reasons.add('evening activity');
      } else {
        score += 5;
        reasons.add('outside ideal travel hours');
      }

      // Distance scoring
      if (previousActivity != null) {
        final distance = _calculateDistanceKm(
          previousActivity.latitude,
          previousActivity.longitude,
          activity.latitude,
          activity.longitude,
        );

        if (distance <= 2) {
          score += 30;
          reasons.add('close to previous stop');
        } else if (distance <= 5) {
          score += 20;
          reasons.add('reasonable travel distance');
        } else if (distance <= 10) {
          score += 10;
          reasons.add('farther travel distance');
        } else {
          score -= 15;
          reasons.add('long travel distance');
        }
      } else {
        score += 10;
        reasons.add('good starting activity');
      }

      results.add(
        OptimizerResult(
          activity: activity,
          score: score,
          reason: 'Moved because: ${reasons.join(', ')}',
        ),
      );

      previousActivity = activity;
    }

    // Highest score
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  int _parseHour(String startTime) {
    try {
      final parts = startTime.split(':');
      return int.parse(parts[0]);
    } catch (_) {
      return 12;
    }
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}