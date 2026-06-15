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
  String _selectedGeoFilter = 'all';
  String? _userCity;
  String? _userProvince;
  String? _userRegion;

  @override
  void initState() {
    super.initState();
    // Initialize future with an empty list first so it's not null before me query returns
    _leaderboardFuture = Future.value([]);
    _loadUserProfileAndLeaderboard();
  }

  Future<void> _loadUserProfileAndLeaderboard() async {
    try {
      final meRes = await ApiService.get('/api/users/me');
      if (meRes.statusCode == 200) {
        final meData = jsonDecode(meRes.body);
        _userCity = meData['city'];
        _userProvince = meData['province'];
        _userRegion = meData['region'];
      }
    } catch (e) {
      debugPrint('Error loading user profile details: $e');
    }
    if (mounted) {
      setState(() {
        _leaderboardFuture = _fetchLeaderboardData();
      });
    }
  }

  Future<List<dynamic>> _fetchLeaderboardData() async {
    String url = '/api/users/leaderboard?timeframe=$_selectedTimeframe&type=$_leaderboardType';
    if (_selectedGeoFilter == 'city' && _userCity != null && _userCity!.isNotEmpty) {
      url += '&city=${Uri.encodeComponent(_userCity!)}';
    } else if (_selectedGeoFilter == 'province' && _userProvince != null && _userProvince!.isNotEmpty) {
      url += '&province=${Uri.encodeComponent(_userProvince!)}';
    } else if (_selectedGeoFilter == 'region' && _userRegion != null && _userRegion!.isNotEmpty) {
      url += '&region=${Uri.encodeComponent(_userRegion!)}';
    }

    final response = await ApiService.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load leaderboard details (Code: ${response.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark ? Colors.white : const Color(0xFF154212);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
        ),
        leading: IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF154212)),
          onPressed: _showFilterSheet,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                color: isDark ? const Color(0xFF1D221C) : const Color(0xFFECEFEA),
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
                              ? brandColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Global',
                          style: TextStyle(
                            color: _leaderboardType == 'global'
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E)),
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
                              ? brandColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Buddies',
                          style: TextStyle(
                            color: _leaderboardType == 'friends'
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E)),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.grey.withOpacity(0.2) : const Color(0xFFC2C9BB)),
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
                    color: isDark ? const Color(0xFFC2C9BB) : const Color(0xFF72796E),
                    selectedColor: brandColor,
                    fillColor: isDark ? const Color(0xFF1D221C) : const Color(0xFFC2C9BB).withOpacity(0.3),
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
          // Geographic Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGeoChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildGeoChip('City (${_userCity ?? 'Local'})', 'city'),
                  const SizedBox(width: 8),
                  _buildGeoChip('Province (${_userProvince ?? 'Local'})', 'province'),
                  const SizedBox(width: 8),
                  _buildGeoChip('Region (${_userRegion ?? 'Local'})', 'region'),
                ],
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

          return Container(
            color: Theme.of(context).cardColor,
            child: CustomScrollView(
              slivers: [
                // Podium Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
                ),
                const SliverToBoxAdapter(
                  child: Divider(height: 1, thickness: 1, color: Colors.transparent),
                ),
                // Rest of the Leaderboard
                if (listUsers.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'That\'s all the active leaders today!',
                          style: TextStyle(color: Color(0xFF72796E), fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B2F1F) : const Color(0xFFF8FAF5),
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
                                    backgroundImage: user['profile_pic_url'] != null
                                      ? NetworkImage(user['profile_pic_url'])
                                      : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                                  ),
                                ],
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text('Tier: $tier', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : const Color(0xFF72796E), fontSize: 12)),
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
                        childCount: listUsers.length,
                      ),
                    ),
                  ),
              ],
            ),
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
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFFE1E3DE),
                backgroundImage: user['profile_pic_url'] != null
                  ? NetworkImage(user['profile_pic_url'])
                  : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),
            // User Name
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
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
                color: accentColor.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: accentColor.withOpacity(0.3)),
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

  Widget _buildGeoChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedGeoFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? (isDark ? Colors.black : Colors.white) 
              : (isDark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E)),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: isDark ? Colors.white : const Color(0xFF154212),
      backgroundColor: isDark ? const Color(0xFF1D221C) : const Color(0xFFECEFEA),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedGeoFilter = value;
            _leaderboardFuture = _fetchLeaderboardData();
          });
        }
      },
    );
  }

void _showFilterSheet() {
    String tempTimeframe = _selectedTimeframe;
    String tempGeoFilter = _selectedGeoFilter;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            Widget buildGeoChip(String label, String value) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final isSelected = tempGeoFilter == value;
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected 
                        ? (isDark ? Colors.black : Colors.white) 
                        : (isDark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E)),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: isDark ? Colors.white : const Color(0xFF154212),
                backgroundColor: isDark ? const Color(0xFF1D221C) : const Color(0xFFECEFEA),
                onSelected: (selected) {
                  if (selected) {
                    setSheetState(() {
                      tempGeoFilter = value;
                    });
                  }
                },
              );
            }

            Widget buildTimeframeButton(String label, String value) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final isSelected = tempTimeframe == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (tempTimeframe != value) {
                      setSheetState(() {
                        tempTimeframe = value;
                      });
                    }
                  },
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isDark ? Colors.white : const Color(0xFF154212)) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected 
                                ? (isDark ? Colors.black : Colors.white) 
                                : (isDark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E)),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF154212),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Timeframe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1D221C) : const Color(0xFFECEFEA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          buildTimeframeButton('Daily', 'daily'),
                          buildTimeframeButton('Monthly', 'monthly'),
                          buildTimeframeButton('Yearly', 'yearly'),
                          buildTimeframeButton('All-Time', 'all-time'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFC2C9BB) : const Color(0xFF42493E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        buildGeoChip('All', 'all'),
                        buildGeoChip('City (${_userCity ?? 'Local'})', 'city'),
                        buildGeoChip('Province (${_userProvince ?? 'Local'})', 'province'),
                        buildGeoChip('Region (${_userRegion ?? 'Local'})', 'region'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _selectedTimeframe = tempTimeframe;
                            _selectedGeoFilter = tempGeoFilter;
                            _leaderboardFuture = _fetchLeaderboardData();
                          });
                        },
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}