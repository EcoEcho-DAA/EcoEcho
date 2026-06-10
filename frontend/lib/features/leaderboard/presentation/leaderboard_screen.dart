import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> top3 = [
      {
        "name": "Princess",
        "xp": 1200,
        "tier": "Ancient Tree",
      },
      {
        "name": "Joan",
        "xp": 1100,
        "tier": "Sapling",
      },
      {
        "name": "Roxane",
        "xp": 1050,
        "tier": "Sapling",
      },
    ];

    final List<Map<String, dynamic>> rest = [
      {
        "name": "Jinrikisha",
        "xp": 1000,
        "tier": "Sapling",
      },
      {
        "name": "User5",
        "xp": 950,
        "tier": "Sprout",
      },
      {
        "name": "User6",
        "xp": 900,
        "tier": "Sprout",
      },
      {
        "name": "User7",
        "xp": 850,
        "tier": "Seed",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: top3.map((user) {
                final String name = user["name"] as String;
                final int xp = user["xp"] as int;
                final String tier = user["tier"] as String;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.emoji_events, size: 36),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("XP: $xp"),
                    Text(tier),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: rest.length,
              itemBuilder: (context, index) {
                final user = rest[index];

                final String name = user["name"] as String;
                final int xp = user["xp"] as int;
                final String tier = user["tier"] as String;

                return ListTile(
                  leading: Text("#${index + 4}"),
                  title: Text(name),
                  subtitle: Text("Tier: $tier"),
                  trailing: Text("XP: $xp"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}