import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../../core/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _dailyChallenge;
  List<dynamic> _trendingPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    try {
      final responses = await Future.wait([
        ApiService.get('/api/users/me'),
        ApiService.get('/api/challenges/daily'),
        ApiService.get('/api/feed/trending'),
      ]);

      final userResponse = responses[0];
      final challengeResponse = responses[1];
      final feedResponse = responses[2];

      if (userResponse.statusCode == 200 && 
          challengeResponse.statusCode == 200 && 
          feedResponse.statusCode == 200) {
        setState(() {
          _userData = jsonDecode(userResponse.body);
          _dailyChallenge = jsonDecode(challengeResponse.body);
          _trendingPosts = jsonDecode(feedResponse.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Detailed Error: $e');
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAF5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF154212)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Color(0xFFBA1A1A))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchHomeData();
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    final currentXp = _userData?['current_xp'] ?? 0;
    final maxXp = _userData?['max_xp'] ?? 500;
    final progressXp = (currentXp / maxXp).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF154212)),
            SizedBox(width: 8),
            Text(
              'EcoEcho',
              style: TextStyle(
                color: Color(0xFF154212),
                fontWeight: FontWeight.bold,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF154212)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFC2C9BB),
              backgroundImage: NetworkImage(
                _userData?['profile_url'] ?? 'https://via.placeholder.com/150',
              ),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        color: const Color(0xFF154212),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4EF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF79564B).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, ${_userData?['first_name'] ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1A),
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You're making a difference today in ${_userData?['city'] ?? 'your city'}.",
                      style: const TextStyle(
                        color: Color(0xFF42493E),
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFC2C9BB).withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF79564B).withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.energy_savings_leaf, size: 64, color: Color(0xFF154212)),
                    const SizedBox(height: 16),
                    Text(
                      _userData?['tier_name'] ?? 'Tier Level',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF154212),
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department, color: Color(0xFF79564B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_userData?['streak_days'] ?? 0} DAY STREAK',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF79564B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('XP Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF42493E))),
                        Text('$currentXp / $maxXp', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF42493E))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressXp,
                        backgroundColor: const Color(0xFFE1E3DE),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF154212)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_dailyChallenge != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5A27),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Challenge',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_dailyChallenge?['title'] ?? 'Complete a task'}\n${_dailyChallenge?['description'] ?? ''}',
                              style: const TextStyle(
                                color: Color(0xFFA1D494),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF154212),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trending',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1A),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF154212),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _trendingPosts.length,
                itemBuilder: (context, index) {
                  final post = _trendingPosts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildFeedItem(post),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFC2C9BB).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF79564B).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                post['image_url'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(post['author_profile_url'] ?? 'https://via.placeholder.com/150'),
                    ),
                    const SizedBox(width: 8),
                    Text(post['author_name'] ?? 'Anonymous', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF42493E))),
                    const SizedBox(width: 8),
                    Text(post['time_ago'] ?? 'Recently', style: const TextStyle(fontSize: 12, color: Color(0xFF72796E))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191C1A))),
                const SizedBox(height: 4),
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF42493E)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 18, color: Color(0xFF154212)),
                    const SizedBox(width: 4),
                    Text('${post['likes'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF154212))),
                    if (post['xp_awarded'] != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.park, size: 18, color: Color(0xFF42493E)),
                      const SizedBox(width: 4),
                      Text('+${post['xp_awarded']} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF42493E))),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}