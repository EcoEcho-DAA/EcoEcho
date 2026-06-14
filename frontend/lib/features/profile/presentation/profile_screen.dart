import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
    _postsFuture = _fetchUserPosts();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      setState(() {
        _profileFuture = _fetchProfileData();
        _postsFuture = _fetchUserPosts();
      });
    }
  }

  Future<List<dynamic>> _fetchUserPosts() async {
    final url = widget.userId == null 
        ? '/api/users/me/posts' 
        : '/api/users/${widget.userId}/posts';
    final response = await ApiService.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load user posts');
    }
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final url = widget.userId == null 
        ? '/api/users/me' 
        : '/api/users/${widget.userId}';
    final response = await ApiService.get(url);
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
        leading: widget.userId != null && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF154212)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          widget.userId == null ? 'My Profile' : 'Buddy Profile',
          style: const TextStyle(
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
                _postsFuture = _fetchUserPosts();
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
                        const SizedBox(height: 8),
                        // UID display and copy button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFEA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC2C9BB).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'UID: ${data['uid'] != null ? (data['uid'].toString().length > 12 ? "${data['uid'].toString().substring(0, 8)}...${data['uid'].toString().substring(data['uid'].toString().length - 4)}" : data['uid']) : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF42493E),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  if (data['uid'] != null) {
                                    Clipboard.setData(ClipboardData(text: data['uid'].toString()));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('UID copied to clipboard!'),
                                        backgroundColor: Color(0xFF154212),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: Color(0xFF154212),
                                ),
                              ),
                            ],
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
                          widget.userId == null 
                            ? 'Keep completing daily challenges to reach the next tier!'
                            : 'This warrior is contributing to a greener future!',
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
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.userId == null ? 'My Eco Log' : 'Eco Log',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1A),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<dynamic>>(
                  future: _postsFuture,
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF154212)));
                    } else if (postSnapshot.hasError) {
                      return Text('Error loading posts: ${postSnapshot.error}');
                    } else if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            widget.userId == null
                                ? 'No green activities logged yet.'
                                : 'No green activities logged by this user yet.',
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: postSnapshot.data!.map((post) {
                        String? rawImageUrl = post['image_url'];
                        String? finalImageUrl;
                        if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
                          if (rawImageUrl.startsWith('/uploads')) {
                            finalImageUrl = '${ApiService.baseUrl}$rawImageUrl';
                          } else {
                            finalImageUrl = rawImageUrl;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildProfilePostCard(
                            timeLocation: _formatRelativeTime(post['created_at']),
                            tagText: post['tag_text'] ?? 'Activity',
                            content: post['caption'] ?? '',
                            imageUrl: finalImageUrl,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatRelativeTime(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 30).floor()}mo ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  Widget _buildProfilePostCard({
    required String timeLocation,
    required String tagText,
    required String content,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C9BB).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF79574C).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeLocation,
                style: const TextStyle(color: Color(0xFF42493E), fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E9E4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tagText,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D5934)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Color(0xFF191C1A)),
          ),
          const SizedBox(height: 12),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  width: double.infinity,
                  color: const Color(0xFFECEFEA),
                  child: const Icon(Icons.image_not_supported, color: Color(0xFFC2C9BB)),
                ),
              ),
            )
        ],
      ),
    );
  }
}
