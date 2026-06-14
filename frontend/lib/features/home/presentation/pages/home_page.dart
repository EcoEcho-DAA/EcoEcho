import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../../../core/network/api_service.dart';
import '../../../profile/presentation/profile_screen.dart';
import 'camera_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;
  bool _isCommunityFeed = true;
  late Future<List<dynamic>> _feedFuture;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _feedFuture = _fetchFeed();
  }

  Future<void> _searchBuddy(String query) async {
    if (query.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF154212)),
      ),
    );

    try {
      final response = await ApiService.post('/api/users/search-buddy', {'query': query});
      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          _showBuddyProfileModal(results[0]);
        }
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errData['error'] ?? 'Buddy UID not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding buddy: $e')),
      );
    }
  }

  void _showBuddyProfileModal(Map<String, dynamic> buddy) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: buddy['uid']),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF154212),
                      child: Text(
                        buddy['username'].toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      buddy['username'] ?? 'Eco Warrior',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF191C1A)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7E9E4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (buddy['tier_name'] ?? 'Seed').toString().toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF154212)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap header to view details',
                      style: TextStyle(fontSize: 10, color: Color(0xFF72796E), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total XP', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${buddy['total_xp'] ?? 0}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191C1A)),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Location', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${buddy['city'] ?? 'Manila'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191C1A)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Province: ${buddy['province'] ?? 'Metro Manila'}',
                style: const TextStyle(color: Color(0xFF79564B), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF154212),
                        side: const BorderSide(color: Color(0xFF154212)),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154212),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('View Profile'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => ProfileScreen(userId: buddy['uid']),
                           ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchFeed() async {
    final response = await ApiService.get('/api/feed/trending');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load feed');
    }
  }

  void _refreshFeed() {
    setState(() {
      _feedFuture = _fetchFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        leadingWidth: 56,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF154212)),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF154212)),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search Buddy UID...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Color(0xFF154212), fontSize: 16),
                textInputAction: TextInputAction.search,
                onSubmitted: (val) {
                  _searchBuddy(val.trim());
                },
              )
            : const Text(
                'EcoEcho',
                style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
              ),
        centerTitle: !_isSearching,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Color(0xFF154212)),
                onPressed: () {},
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLogActivitySection(),
          const SizedBox(height: 24),
          _buildFeedToggle(),
          const SizedBox(height: 16),
          if (_isCommunityFeed) ...[
            FutureBuilder<List<dynamic>>(
              future: _feedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Color(0xFF154212)),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Failed to load feed: ${snapshot.error}'),
                          TextButton(
                            onPressed: _refreshFeed,
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No posts yet in the community. Be the first!'),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.map((post) {
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
                      child: PostCard(
                        postData: post,
                        finalImageUrl: finalImageUrl,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Friends feed is empty.'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogActivitySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C9BB).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF79574C).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF2D5A27),
            child: Icon(Icons.add_a_photo, color: Color(0xFF9DD090), size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Log Green Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF191C1A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload a photo to earn XP and inspire the community.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF42493E), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Fetch the available cameras from the device hardware
                final cameras = await availableCameras();

                if (!mounted) return;

                // Navigate to the custom camera interface
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(cameras: cameras),
                  ),
                );
              } catch (e) {
                debugPrint('Error fetching cameras: $e');
              }
            },
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Upload Proof', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154212),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFFC2C9BB).withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isCommunityFeed = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _isCommunityFeed ? const Color(0xFF154212) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isCommunityFeed ? const Color(0xFF154212) : const Color(0xFF42493E),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isCommunityFeed = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !_isCommunityFeed ? const Color(0xFF154212) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Friends',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isCommunityFeed ? const Color(0xFF154212) : const Color(0xFF42493E),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String? finalImageUrl;

  const PostCard({
    Key? key,
    required this.postData,
    this.finalImageUrl,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likesCount;
  late int downvotesCount;
  late int commentsCount;
  late bool isLiked;
  late bool isDownvoted;
  bool isVoting = false;

  @override
  void initState() {
    super.initState();
    likesCount = int.tryParse(widget.postData['likes_count']?.toString() ?? '0') ?? 0;
    downvotesCount = int.tryParse(widget.postData['downvotes_count']?.toString() ?? '0') ?? 0;
    commentsCount = int.tryParse(widget.postData['comments_count']?.toString() ?? '0') ?? 0;
    isLiked = widget.postData['is_liked_by_me'] == true;
    isDownvoted = widget.postData['is_downvoted_by_me'] == true;
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

  Future<void> _toggleLike() async {
    if (isVoting) return;
    setState(() => isVoting = true);

    try {
      final postId = widget.postData['id'];
      if (isLiked) {
        final response = await ApiService.delete('/api/posts/$postId/like');
        if (response.statusCode == 200) {
          setState(() {
            isLiked = false;
            likesCount--;
          });
        }
      } else {
        final response = await ApiService.post('/api/posts/$postId/like', {});
        if (response.statusCode == 200) {
          setState(() {
            isLiked = true;
            likesCount++;
            if (isDownvoted) {
              isDownvoted = false;
              downvotesCount--;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    } finally {
      setState(() => isVoting = false);
    }
  }

  Future<void> _toggleDownvote() async {
    if (isVoting) return;
    setState(() => isVoting = true);

    try {
      final postId = widget.postData['id'];
      if (isDownvoted) {
        final response = await ApiService.delete('/api/posts/$postId/downvote');
        if (response.statusCode == 200) {
          setState(() {
            isDownvoted = false;
            downvotesCount--;
          });
        }
      } else {
        final response = await ApiService.post('/api/posts/$postId/downvote', {});
        if (response.statusCode == 200) {
          setState(() {
            isDownvoted = true;
            downvotesCount++;
            if (isLiked) {
              isLiked = false;
              likesCount--;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling downvote: $e');
    } finally {
      setState(() => isVoting = false);
    }
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        postId: widget.postData['id'],
        onCommentCountChanged: (int newCount) {
          setState(() {
            commentsCount = newCount;
          });
        },
      ),
    );
  }

  Future<void> _reportPost() async {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report Post', style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please state the reason for reporting this post:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Spam, offensive content',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF154212)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Report'),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason for reporting.')),
                );
                return;
              }
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(dialogContext);
              try {
                final postId = widget.postData['id'];
                final response = await ApiService.post('/api/posts/$postId/report', {'reason': reason});
                if (response.statusCode == 201) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Report submitted successfully. Thank you!')),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to submit report (Code: ${response.statusCode})')),
                  );
                }
              } catch (e) {
                debugPrint('Error reporting post: $e');
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.postData['author_name'] ?? 'Unknown User';
    final content = widget.postData['caption'] ?? '';
    final tagText = widget.postData['tag_text'] ?? 'Activity';
    final imageUrl = widget.finalImageUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2C9BB).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF79574C).withOpacity(0.04),
            blurRadius: 20,
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
              GestureDetector(
                onTap: () {
                  final authorUid = widget.postData['author_uid'];
                  if (authorUid != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: authorUid.toString()),
                      ),
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFECEFEA),
                      radius: 20,
                      backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF191C1A)),
                        ),
                        Text(
                          _formatRelativeTime(widget.postData['created_at']),
                          style: const TextStyle(color: Color(0xFF42493E), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15411F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          '+50 XP',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, color: Color(0xFFBA1A1A), size: 20),
                    onPressed: _reportPost,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7E9E4),
              border: Border.all(color: const Color(0xFF2D5934).withOpacity(0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.park, size: 16, color: Color(0xFF2D5934)),
                const SizedBox(width: 6),
                Text(
                  tagText,
                  style: const TextStyle(color: Color(0xFF2D5934), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 16, color: Color(0xFF191C1A), height: 1.5),
          ),
          const SizedBox(height: 12),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_not_supported, size: 48, color: Color(0xFFC2C9BB)),
                ),
              ),
            )
          else
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, size: 48, color: Color(0xFFC2C9BB)),
            ),
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFC2C9BB).withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.arrow_circle_up : Icons.arrow_circle_up_outlined,
                      color: isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        color: isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: _toggleDownvote,
                child: Row(
                  children: [
                    Icon(
                      isDownvoted ? Icons.arrow_circle_down : Icons.arrow_circle_down_outlined,
                      color: isDownvoted ? const Color(0xFFBA1A1A) : const Color(0xFF42493E),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      downvotesCount.toString(),
                      style: TextStyle(
                        color: isDownvoted ? const Color(0xFFBA1A1A) : const Color(0xFF42493E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: _showCommentSheet,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Color(0xFF42493E), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      commentsCount.toString(),
                      style: const TextStyle(color: Color(0xFF42493E), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentSheet extends StatefulWidget {
  final int postId;
  final Function(int) onCommentCountChanged;

  const CommentSheet({
    Key? key,
    required this.postId,
    required this.onCommentCountChanged,
  }) : super(key: key);

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  List<dynamic> comments = [];
  bool isLoading = true;
  bool isPosting = false;
  final TextEditingController _commentController = TextEditingController();
  String? currentUserUid;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchComments();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await ApiService.get('/api/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentUserUid = data['uid'];
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch current user: $e');
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await ApiService.get('/api/posts/${widget.postId}/comments');
      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body) as List<dynamic>;
          isLoading = false;
        });
        widget.onCommentCountChanged(comments.length);
      }
    } catch (e) {
      debugPrint('Failed to load comments: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || isPosting) return;

    setState(() => isPosting = true);
    try {
      final response = await ApiService.post('/api/posts/${widget.postId}/comment', {'content': content});
      if (response.statusCode == 201) {
        _commentController.clear();
        await _fetchComments();
      }
    } catch (e) {
      debugPrint('Failed to post comment: $e');
    } finally {
      setState(() => isPosting = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final response = await ApiService.delete('/api/posts/${widget.postId}/comment/$commentId');
      if (response.statusCode == 200) {
        await _fetchComments();
      }
    } catch (e) {
      debugPrint('Failed to delete comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFC2C9BB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF154212)),
            ),
            const Divider(),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              )
            else if (comments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No comments yet. Be the first to comment!'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFECEFEA),
                            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment['author_name'] ?? 'Unknown User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191C1A)),
                                    ),
                                    const Spacer(),
                                    if (currentUserUid != null && comment['user_uid'] == currentUserUid)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                        onPressed: () => _deleteComment(comment['id']),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['content'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF42493E)),
                                ),
                                const SizedBox(height: 6),
                                CommentVoteButton(
                                  commentData: comment,
                                  onVoteChanged: () {
                                    // Child manages its state locally, but trigger reload if needed.
                                  },
                                ),
                                const SizedBox(height: 4),
                                Divider(height: 1, color: const Color(0xFFC2C9BB).withOpacity(0.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFECEFEA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  isPosting
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF154212)),
                          onPressed: _postComment,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentVoteButton extends StatefulWidget {
  final Map<String, dynamic> commentData;
  final VoidCallback onVoteChanged;

  const CommentVoteButton({
    Key? key,
    required this.commentData,
    required this.onVoteChanged,
  }) : super(key: key);

  @override
  State<CommentVoteButton> createState() => _CommentVoteButtonState();
}

class _CommentVoteButtonState extends State<CommentVoteButton> {
  late int likesCount;
  late int downvotesCount;
  late bool isLiked;
  late bool isDownvoted;
  bool isVoting = false;

  @override
  void initState() {
    super.initState();
    likesCount = int.tryParse(widget.commentData['likes_count']?.toString() ?? '0') ?? 0;
    downvotesCount = int.tryParse(widget.commentData['downvotes_count']?.toString() ?? '0') ?? 0;
    isLiked = widget.commentData['is_liked_by_me'] == true;
    isDownvoted = widget.commentData['is_downvoted_by_me'] == true;
  }

  Future<void> _toggleLike() async {
    if (isVoting) return;
    setState(() => isVoting = true);

    try {
      final commentId = widget.commentData['id'];
      if (isLiked) {
        final response = await ApiService.delete('/api/comments/$commentId/like');
        if (response.statusCode == 200) {
          setState(() {
            isLiked = false;
            likesCount--;
          });
          widget.onVoteChanged();
        }
      } else {
        final response = await ApiService.post('/api/comments/$commentId/like', {});
        if (response.statusCode == 200) {
          setState(() {
            isLiked = true;
            likesCount++;
            if (isDownvoted) {
              isDownvoted = false;
              downvotesCount--;
            }
          });
          widget.onVoteChanged();
        }
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
    } finally {
      setState(() => isVoting = false);
    }
  }

  Future<void> _toggleDownvote() async {
    if (isVoting) return;
    setState(() => isVoting = true);

    try {
      final commentId = widget.commentData['id'];
      if (isDownvoted) {
        final response = await ApiService.delete('/api/comments/$commentId/downvote');
        if (response.statusCode == 200) {
          setState(() {
            isDownvoted = false;
            downvotesCount--;
          });
          widget.onVoteChanged();
        }
      } else {
        final response = await ApiService.post('/api/comments/$commentId/downvote', {});
        if (response.statusCode == 200) {
          setState(() {
            isDownvoted = true;
            downvotesCount++;
            if (isLiked) {
              isLiked = false;
              likesCount--;
            }
          });
          widget.onVoteChanged();
        }
      }
    } catch (e) {
      debugPrint('Error toggling comment downvote: $e');
    } finally {
      setState(() => isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.arrow_circle_up : Icons.arrow_circle_up_outlined,
                color: isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                likesCount.toString(),
                style: TextStyle(
                  color: isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: _toggleDownvote,
          child: Row(
            children: [
              Icon(
                isDownvoted ? Icons.arrow_circle_down : Icons.arrow_circle_down_outlined,
                color: isDownvoted ? const Color(0xFFBA1A1A) : const Color(0xFF42493E),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                downvotesCount.toString(),
                style: TextStyle(
                  color: isDownvoted ? const Color(0xFFBA1A1A) : const Color(0xFF42493E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}