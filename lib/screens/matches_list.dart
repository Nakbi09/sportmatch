import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MatchesListScreen extends StatelessWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance.collection('matches')
        .where('participants', arrayContains: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes matchs')),
      body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: ref.snapshots(),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Aucun match pour le moment.'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data();
              final other = (data['participants'] as List).firstWhere((x) => x != uid, orElse: ()=> '???');
              final subtitle = data['lastMessage'] ?? 'Nouveau match !';
              return ListTile(
                title: Text('Avec $other'),
                subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(matchId: d.id),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
