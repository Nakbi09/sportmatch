import 'package:flutter/material.dart';
import 'create_playcard.dart';
import 'swipe_feed.dart';
import 'matches_list.dart';

class HomeTabs extends StatelessWidget {
  const HomeTabs({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('SportMatch'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Jouer'),
            Tab(text: 'Créer annonce'),
            Tab(text: 'Matchs'),
          ]),
        ),
        body: const TabBarView(
          children: [
            SwipeFeedScreen(),
            CreatePlayCardScreen(),
            MatchesListScreen(),
          ],
        ),
      ),
    );
  }
}
