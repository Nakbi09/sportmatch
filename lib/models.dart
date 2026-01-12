import 'package:cloud_firestore/cloud_firestore.dart';

class SportPref {
  final String name;  // 'tennis'
  final String level; // 'deb'|'inter'|'conf'
  const SportPref({required this.name, required this.level});
  Map<String, dynamic> toMap() => {'name': name, 'level': level};
  factory SportPref.fromMap(Map<String, dynamic> m)
    => SportPref(name: (m['name'] ?? '') as String, level: (m['level'] ?? 'inter') as String);
}

class UserDoc {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final double radiusKm;
  final double? lat, lng;
  final List<SportPref> sports;

  const UserDoc({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.radiusKm,
    this.lat, this.lng,
    required this.sports,
  });

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'photoUrl': photoUrl,
    'radiusKm': radiusKm,
    'homeLocation': (lat != null && lng != null) ? {'lat': lat, 'lng': lng} : null,
    'sports': sports.map((e) => e.toMap()).toList(),
  };

  factory UserDoc.fromSnap(DocumentSnapshot s) {
    final m = (s.data() as Map<String, dynamic>? ?? {});
    final hl = m['homeLocation'] as Map<String, dynamic>?;
    final list = (m['sports'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SportPref.fromMap)
        .toList();

    return UserDoc(
      uid: s.id,
      displayName: (m['displayName'] ?? '') as String,
      photoUrl: m['photoUrl'] as String?,
      radiusKm: (m['radiusKm'] is num) ? (m['radiusKm'] as num).toDouble() : 8.0,
      lat: (hl?['lat'] as num?)?.toDouble(),
      lng: (hl?['lng'] as num?)?.toDouble(),
      sports: list,
    );
  }
}

class PlayCard {
  final String id;
  final String ownerUid;
  final String sport;
  final String level;
  final DateTime start, end;
  final double lat, lng;
  final String placeName;
  final String status; // 'open'|'matched'|'expired'

  const PlayCard({
    required this.id,
    required this.ownerUid,
    required this.sport,
    required this.level,
    required this.start,
    required this.end,
    required this.lat,
    required this.lng,
    required this.placeName,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'ownerUid': ownerUid,
    'sport': sport,
    'level': level,
    'startTime': Timestamp.fromDate(start),
    'endTime': Timestamp.fromDate(end),
    'location': {'lat': lat, 'lng': lng, 'name': placeName},
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory PlayCard.fromSnap(DocumentSnapshot d) {
    final m = (d.data() as Map<String, dynamic>? ?? {});
    final loc = (m['location'] as Map<String, dynamic>? ?? {});
    final tsStart = m['startTime'] as Timestamp?;
    final tsEnd = m['endTime'] as Timestamp?;
    return PlayCard(
      id: d.id,
      ownerUid: (m['ownerUid'] ?? '') as String,
      sport: (m['sport'] ?? '') as String,
      level: (m['level'] ?? 'inter') as String,
      start: (tsStart?.toDate()) ?? DateTime.now(),
      end: (tsEnd?.toDate()) ?? DateTime.now().add(const Duration(hours: 1)),
      lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
      placeName: (loc['name'] ?? 'Lieu') as String,
      status: (m['status'] ?? 'open') as String,
    );
  }
}
