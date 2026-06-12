import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final response = await ApiService.get('/api/users/me');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load profile details (Code: ${response.statusCode})');
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
          'My Profile',
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
                _profileFuture = _fetchProfileData();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
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
                          _profileFuture = _fetchProfileData();
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
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No profile data found.'));
          }

          final data = snapshot.data!;
          final username = data['username'] ?? 'Eco Warrior';
          final email = data['email'] ?? '';
          final city = data['city'] ?? 'Manila';
          final province = data['province'] ?? 'Metro Manila';
          final xp = data['total_xp'] ?? 0;
          final tier = data['tier_name']?.toString() ?? 'Seed';
          final String tierLower = tier.toLowerCase();
          
          int nextTierXp = 500;
          int currentTierBase = 0;
          
          if (tierLower.contains('sprout')) {
            currentTierBase = 500;
            nextTierXp = 1200;
          } else if (tierLower.contains('sapling')) {
            currentTierBase = 1200;
            nextTierXp = 2500;
          } else if (tierLower.contains('ancient')) {
            currentTierBase = 2500;
            nextTierXp = 5000;
          }

          double progress = 0.0;
          if (xp >= nextTierXp) {
            progress = 1.0;
          } else if (xp > currentTierBase) {
            progress = (xp - currentTierBase) / (nextTierXp - currentTierBase);
          }
          progress = progress.clamp(0.0, 1.0);

          final initial = username.isNotEmpty ? username[0].toUpperCase() : 'E';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Stylized premium circular card container
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  shadowColor: const Color(0xFF154212).withValues(alpha: 0.1),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                    child: Column(
                      children: [
                        // User Profile Initial avatar badge
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE1E3DE),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFF154212),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Real 'username' header text
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1A),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email address
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF72796E),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 12),
                        // City, Province Locator Caption
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Color(0xFF79564B)),
                            const SizedBox(width: 4),
                            Text(
                              '$city, $province',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF79564B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Progress Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tier.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF154212),
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              '$xp XP / $nextTierXp XP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF42493E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: const Color(0xFFE1E3DE),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF154212)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keep completing daily challenges to reach the next tier!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF42493E).withValues(alpha: 0.8),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
