import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../../../core/network/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _feedFuture = _fetchFeed();
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
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5A27),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'L2',
                    style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'EcoEcho',
          style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
  late int commentsCount;
  late bool isLiked;
  bool isLiking = false;

  @override
  void initState() {
    super.initState();
    likesCount = int.tryParse(widget.postData['likes_count']?.toString() ?? '0') ?? 0;
    commentsCount = int.tryParse(widget.postData['comments_count']?.toString() ?? '0') ?? 0;
    isLiked = widget.postData['is_liked_by_me'] == true;
  }

  Future<void> _toggleLike() async {
    if (isLiking) return;
    setState(() => isLiking = true);

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
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    } finally {
      setState(() => isLiking = false);
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
              Row(
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
                      const Text(
                        'Just now',
                        style: TextStyle(color: Color(0xFF42493E), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
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
                      isLiked ? Icons.eco : Icons.eco_outlined,
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
              const Spacer(),
              const Icon(Icons.share, color: Color(0xFF42493E), size: 22),
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

  @override
  void initState() {
    super.initState();
    _fetchComments();
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
                    return ListTile(
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                      ),
                      title: Text(
                        comment['author_name'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(comment['content'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () => _deleteComment(comment['id']),
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