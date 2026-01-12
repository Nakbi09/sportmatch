import 'dart:math';
import 'models.dart';

double _toRad(double d) => d * (pi / 180.0);

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

bool _overlapMinutes(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd, int minMinutes) {
  if (!aEnd.isAfter(aStart) || !bEnd.isAfter(bStart)) return false;
  final start = aStart.isAfter(bStart) ? aStart : bStart;
  final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
  final minutes = end.difference(start).inMinutes;
  return minutes >= minMinutes;
}

int _lvl(String l) => const {'deb': 1, 'inter': 2, 'conf': 3}[l] ?? 2;
bool _lvlOk(String a, String b, {int tol = 1}) => (_lvl(a) - _lvl(b)).abs() <= tol;

/// Basic compatibility for MVP
bool compatible(PlayCard me, PlayCard other, double maxKm, {int minOverlap = 45}) {
  if (me.ownerUid == other.ownerUid) return false;
  if (me.sport != other.sport) return false;
  if (!_overlapMinutes(me.start, me.end, other.start, other.end, minOverlap)) return false;
  if (!_lvlOk(me.level, other.level)) return false;
  final d = haversineKm(me.lat, me.lng, other.lat, other.lng);
  return d <= maxKm;
}
