import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../matching.dart';
import '../models.dart';

class SwipeFeedScreen extends StatelessWidget {
  const SwipeFeedScreen({super.key});

  Future<Set<String>> _alreadySwipedIds(String uid) async {
    final qs = await FirebaseFirestore.instance
        .collection('swipes')
        .where('fromUid', isEqualTo: uid)
        .get();
    return qs.docs.map((d) => (d.data()['toPlaycardId'] as String)).toSet();
  }

  /// deterministic ID: "fromUid_toPlaycardId" to prevent duplicates
  String _swipeDocId(String fromUid, String toPlaycardId) => '${fromUid}_$toPlaycardId';

  Future<void> _tryCreateMatchIfReciprocal({
    required String myUid,
    required PlayCard myCard,
    required PlayCard other,
  }) async {
    final db = FirebaseFirestore.instance;

    // Did the other user already like my card?
    final otherSwipeId = '${other.ownerUid}_${myCard.id}';
    final otherLike = await db.collection('swipes').doc(otherSwipeId).get();
    if (!otherLike.exists) return;

    // Deterministic matchId
    final ids = [myUid, other.ownerUid]..sort();
    final matchId = '${ids[0]}_${ids[1]}';

    await db.collection('matches').doc(matchId).set({
      'userA': ids[0],
      'userB': ids[1],
      'participants': ids,
      'playcardA': myCard.id,
      'playcardB': other.id,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': "C’est un match ! Dites bonjour 👋",
    }, SetOptions(merge: true));

    await db.collection('chats').doc(matchId).collection('messages').add({
      'fromUid': null,
      'text': "C’est un match ! Dites bonjour 👋",
      'type': 'system',
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final pcRef = FirebaseFirestore.instance.collection('playcards');

    return FutureBuilder<Set<String>>(
      future: _alreadySwipedIds(uid),
      builder: (c, swipedSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: pcRef.where('status', isEqualTo: 'open').snapshots(),
          builder: (c, snap) {
            if (!snap.hasData || swipedSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snap.data!.docs.map((d) => PlayCard.fromSnap(d)).toList();
            final mine = all.where((p) => p.ownerUid == uid).toList();
            final others = all.where((p) => p.ownerUid != uid).toList();

            if (mine.isEmpty) {
              return Center(
                child: Text(
                  'Crée d’abord une annonce dans l’onglet "Créer annonce".',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            }

            // MVP: take first active card as "me"
            final me = mine.first;
            final swiped = swipedSnap.data!;
            final candidates = others
                .where((o) => !swiped.contains(o.id))
                .where((o) => compatible(me, o, 8 /* km */, minOverlap: 45))
                .toList();

            if (candidates.isEmpty) {
              return const Center(child: Text('Aucun joueur compatible pour le moment.'));
            }

            return ListView.separated(
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final pc = candidates[i];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text('${pc.sport.toUpperCase()} • ${pc.level} • ${pc.placeName}'),
                    subtitle: Text(
                      'De ${pc.start} à ${pc.end}',
                      maxLines: 1,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () async {
                            final id = _swipeDocId(uid, pc.id);
                            await FirebaseFirestore.instance.collection('swipes').doc(id).set({
                              'fromUid': uid,
                              'toPlaycardId': pc.id,
                              'value': 'pass',
                              'createdAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('⛔ Pass enregistré')));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite),
                          onPressed: () async {
                            final id = _swipeDocId(uid, pc.id);
                            await FirebaseFirestore.instance.collection('swipes').doc(id).set({
                              'fromUid': uid,
                              'toPlaycardId': pc.id,
                              'value': 'like',
                              'createdAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('👍 Like envoyé')));

                            // Try to create match if reciprocal
                            await _tryCreateMatchIfReciprocal(
                              myUid: uid,
                              myCard: me,
                              other: pc,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
