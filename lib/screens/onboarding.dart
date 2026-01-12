import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth.dart';
import 'home_tabs.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  final _auth = AuthService();
  User? _user;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      _auth.changes.listen((u) => setState(() => _user = u));
      if (FirebaseAuth.instance.currentUser == null) {
        await _auth.signInAnonymously();
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'displayName': 'Joueur ${uid.substring(0, 4)}',
          'photoUrl': null,
          'radiusKm': 8,
          'homeLocation': null,
          'sports': [
            {'name': 'tennis', 'level': 'inter'}
          ],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d’initialisation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const HomeTabs();
  }
}
