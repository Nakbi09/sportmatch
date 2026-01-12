import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreatePlayCardScreen extends StatefulWidget {
  const CreatePlayCardScreen({super.key});
  @override
  State<CreatePlayCardScreen> createState() => _CreatePlayCardScreenState();
}

class _CreatePlayCardScreenState extends State<CreatePlayCardScreen> {
  final _form = GlobalKey<FormState>();
  String sport = 'tennis';
  String level = 'inter';
  DateTime start = DateTime.now().add(const Duration(hours: 2));
  DateTime end = DateTime.now().add(const Duration(hours: 3));
  String placeName = 'Parc de Gerland';
  double lat = 45.729, lng = 4.827;

  Future<void> _pickDateTime({required bool isStart}) async {
    final base = isStart ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        start = dt;
        if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));
      } else {
        end = dt;
        if (!end.isAfter(start)) start = end.subtract(const Duration(hours: 1));
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L’heure de fin doit être après le début.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('playcards').add({
      'ownerUid': uid,
      'sport': sport,
      'level': level,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'location': {'lat': lat, 'lng': lng, 'name': placeName},
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce créée ✔')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM • HH:mm', 'fr_FR');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _form,
        child: ListView(
          children: [
            DropdownButtonFormField(
              value: sport,
              items: const [
                DropdownMenuItem(value: 'tennis', child: Text('Tennis')),
                DropdownMenuItem(value: 'football', child: Text('Football')),
                DropdownMenuItem(value: 'basket', child: Text('Basket')),
              ],
              onChanged: (v) => setState(() => sport = v as String),
              decoration: const InputDecoration(labelText: 'Sport'),
            ),
            DropdownButtonFormField(
              value: level,
              items: const [
                DropdownMenuItem(value: 'deb', child: Text('Débutant')),
                DropdownMenuItem(value: 'inter', child: Text('Intermédiaire')),
                DropdownMenuItem(value: 'conf', child: Text('Confirmé')),
              ],
              onChanged: (v) => setState(() => level = v as String),
              decoration: const InputDecoration(labelText: 'Niveau'),
            ),
            TextFormField(
              initialValue: placeName,
              decoration: const InputDecoration(labelText: 'Lieu'),
              onChanged: (v) => placeName = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Début : ${fmt.format(start)}'),
              trailing: const Icon(Icons.schedule),
              onTap: () => _pickDateTime(isStart: true),
            ),
            ListTile(
              title: Text('Fin : ${fmt.format(end)}'),
              trailing: const Icon(Icons.schedule),
              onTap: () => _pickDateTime(isStart: false),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Créer l’annonce')),
          ],
        ),
      ),
    );
  }
}
