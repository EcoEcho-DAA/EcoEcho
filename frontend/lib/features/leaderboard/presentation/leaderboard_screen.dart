import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../profile/presentation/profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<dynamic>> _leaderboardFuture;
  String _selectedTimeframe = 'all-time';
  String _leaderboardType = 'global';

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _fetchLeaderboardData();
  }

  Future<List<dynamic>> _fetchLeaderboardData() async {
    final response = await ApiService.get('/api/users/leaderboard?timeframe=$_selectedTimeframe&type=$_leaderboardType');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load leaderboard details (Code: ${response.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Color(0xFF154212),
            fontWeight: FontWeight.bold,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
        actions: [

          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF154212)),
            onPressed: () {
              setState(() {
                _leaderboardFuture = _fetchLeaderboardData();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Leaderboard Type Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFEA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_leaderboardType != 'global') {
                          setState(() {
                            _leaderboardType = 'global';
                            _leaderboardFuture = _fetchLeaderboardData();
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _leaderboardType == 'global'
                              ? const Color(0xFF154212)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Global',
                          style: TextStyle(
                            color: _leaderboardType == 'global'
                                ? Colors.white
                                : const Color(0xFF42493E),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_leaderboardType != 'friends') {
                          setState(() {
                            _leaderboardType = 'friends';
                            _leaderboardFuture = _fetchLeaderboardData();
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _leaderboardType == 'friends'
                              ? const Color(0xFF154212)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Friends',
                          style: TextStyle(
                            color: _leaderboardType == 'friends'
                                ? Colors.white
                                : const Color(0xFF42493E),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC2C9BB)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = (constraints.maxWidth - 6) / 4;
                  return ToggleButtons(
                    constraints: BoxConstraints.expand(width: buttonWidth, height: 36),
                    isSelected: [
                      _selectedTimeframe == 'daily',
                      _selectedTimeframe == 'monthly',
                      _selectedTimeframe == 'yearly',
                      _selectedTimeframe == 'all-time',
                    ],
                    onPressed: (index) {
                      final timeframes = ['daily', 'monthly', 'yearly', 'all-time'];
                      if (_selectedTimeframe != timeframes[index]) {
                        setState(() {
                          _selectedTimeframe = timeframes[index];
                          _leaderboardFuture = _fetchLeaderboardData();
                        });
                      }
                    },
                    color: const Color(0xFF72796E),
                    selectedColor: const Color(0xFF154212),
                    fillColor: const Color(0xFFC2C9BB).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(7),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 12,
                    ),
                    children: const [
                      FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Daily'))),
                      FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Monthly'))),
                      FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Yearly'))),
                      FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('All-Time'))),
                    ],
                  );
                }
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF154212)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _leaderboardFuture = _fetchLeaderboardData();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154212),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No leaderboard data available.'));
          }

          final List<dynamic> users = snapshot.data!;
          final dynamic firstPlace = users.isNotEmpty ? users[0] : null;
          final dynamic secondPlace = users.length > 1 ? users[1] : null;
          final dynamic thirdPlace = users.length > 2 ? users[2] : null;
          final List<dynamic> listUsers = users.length > 3 ? users.sublist(3) : [];

          return Column(
            children: [
              // Podium Section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAF5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 2nd Place (Left)
                    _buildPodiumSpot(
                      user: secondPlace,
                      rank: 2,
                      accentColor: const Color(0xFF7F8C8D), // Silver style
                      height: 80,
                      avatarRadius: 26,
                    ),
                    // 1st Place (Center)
                    _buildPodiumSpot(
                      user: firstPlace,
                      rank: 1,
                      accentColor: const Color(0xFFF1C40F), // Gold style
                      height: 110,
                      avatarRadius: 34,
                    ),
                    // 3rd Place (Right)
                    _buildPodiumSpot(
                      user: thirdPlace,
                      rank: 3,
                      accentColor: const Color(0xFFD35400), // Bronze style
                      height: 65,
                      avatarRadius: 22,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE1E3DE)),
              // Rest of the Leaderboard
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: listUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'That\'s all the active leaders today!',
                            style: TextStyle(color: Color(0xFF72796E), fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          itemCount: listUsers.length,
                          itemBuilder: (context, index) {
                            final user = listUsers[index];
                            final int rank = index + 4;
                            final String name = user['username'] ?? 'Anonymous';
                            final int xp = (user['total_xp'] is int) ? user['total_xp'] : int.tryParse(user['total_xp']?.toString() ?? '0') ?? 0;
                            final String tier = user['tier_name'] ?? 'Seed';
                            final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              color: const Color(0xFFF8FAF5),
                              child: ListTile(
                                onTap: () {
                                  if (user['uid'] != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(userId: user['uid'].toString()),
                                      ),
                                    );
                                  }
                                },
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$rank',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF72796E),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFC2C9BB),
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF154212),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF191C1A),
                                  ),
                                ),
                                subtitle: Text('Tier: $tier', style: const TextStyle(color: Color(0xFF72796E), fontSize: 12)),
                                trailing: Text(
                                  '$xp XP',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF154212),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ],
),
    );
  }

  Widget _buildPodiumSpot({
    required dynamic user,
    required int rank,
    required Color accentColor,
    required double height,
    required double avatarRadius,
  }) {
    if (user == null) {
      return const Expanded(child: SizedBox.shrink());
    }

    final String name = user['username'] ?? 'Anonymous';
    final int xp = (user['total_xp'] is int) ? user['total_xp'] : int.tryParse(user['total_xp']?.toString() ?? '0') ?? 0;
    final String tier = user['tier_name'] ?? 'Seed';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (user['uid'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: user['uid'].toString()),
              ),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Crown/Trophy Icon
            if (rank == 1)
              const Icon(Icons.emoji_events, color: Color(0xFFF1C40F), size: 32)
            else if (rank == 2)
              const Icon(Icons.emoji_events, color: Color(0xFF7F8C8D), size: 26)
            else
              const Icon(Icons.emoji_events, color: Color(0xFFD35400), size: 22),
            const SizedBox(height: 8),
            // Stylized Avatar Badge with Border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFFE1E3DE),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: avatarRadius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF154212),
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // User Name
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF191C1A),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // XP
            Text(
              '$xp XP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            // Tier Name
            Text(
              tier,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF72796E),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Solid base representing the platform
            Container(
              height: height,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}