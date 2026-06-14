import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../profile/presentation/profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostDetailScreen({Key? key, required this.postData}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Map<String, dynamic> _post;
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isVoting = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isPostingComment = false;

  late int _likesCount;
  late int _downvotesCount;
  late int _commentsCount;
  late bool _isLiked;
  late bool _isDownvoted;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.postData);
    _likesCount = int.tryParse(_post['likes_count']?.toString() ?? '0') ?? 0;
    _downvotesCount = int.tryParse(_post['downvotes_count']?.toString() ?? '0') ?? 0;
    _commentsCount = int.tryParse(_post['comments_count']?.toString() ?? '0') ?? 0;
    _isLiked = _post['is_liked_by_me'] == true;
    _isDownvoted = _post['is_downvoted_by_me'] == true;

    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await ApiService.get('/api/posts/${_post['id']}/comments');
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _comments = jsonDecode(response.body) as List<dynamic>;
          _commentsCount = _comments.length;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load comments: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isVoting) return;
    setState(() => _isVoting = true);

    try {
      final postId = _post['id'];
      if (_isLiked) {
        final response = await ApiService.delete('/api/posts/$postId/like');
        if (response.statusCode == 200) {
          setState(() {
            _isLiked = false;
            _likesCount--;
          });
        }
      } else {
        final response = await ApiService.post('/api/posts/$postId/like', {});
        if (response.statusCode == 200) {
          setState(() {
            _isLiked = true;
            _likesCount++;
            if (_isDownvoted) {
              _isDownvoted = false;
              _downvotesCount--;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  Future<void> _toggleDownvote() async {
    if (_isVoting) return;
    setState(() => _isVoting = true);

    try {
      final postId = _post['id'];
      if (_isDownvoted) {
        final response = await ApiService.delete('/api/posts/$postId/downvote');
        if (response.statusCode == 200) {
          setState(() {
            _isDownvoted = false;
            _downvotesCount--;
          });
        }
      } else {
        final response = await ApiService.post('/api/posts/$postId/downvote', {});
        if (response.statusCode == 200) {
          setState(() {
            _isDownvoted = true;
            _downvotesCount++;
            if (_isLiked) {
              _isLiked = false;
              _likesCount--;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling downvote: $e');
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);
    try {
      final response = await ApiService.post('/api/posts/${_post['id']}/comment', {'content': content});
      if (response.statusCode == 201) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        await _fetchComments();
      }
    } catch (e) {
      debugPrint('Failed to post comment: $e');
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final authorName = _post['author_name'] ?? 'Unknown User';
    final caption = _post['caption'] ?? '';
    final tagText = _post['tag_text'] ?? 'Activity';
    final rawImageUrl = _post['image_url'];
    
    String? finalImageUrl;
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      if (rawImageUrl.startsWith('/uploads')) {
        finalImageUrl = '${ApiService.baseUrl}$rawImageUrl';
      } else {
        finalImageUrl = rawImageUrl;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF154212)),
        title: const Text(
          'Post Details',
          style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final authorUid = _post['author_uid'];
                          if (authorUid != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(userId: authorUid.toString()),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFECEFEA),
                          radius: 24,
                          backgroundImage: _post['profile_pic_url'] != null
                            ? NetworkImage(_post['profile_pic_url'])
                            : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final authorUid = _post['author_uid'];
                                if (authorUid != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(userId: authorUid.toString()),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF191C1A),
                                ),
                              ),
                            ),
                            Text(
                              _formatRelativeTime(_post['created_at']),
                              style: const TextStyle(color: Color(0xFF72796E), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15411F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '+50 XP',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tag/Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E9E4),
                      border: Border.all(color: const Color(0xFF2D5934).withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.park, size: 18, color: Color(0xFF2D5934)),
                        const SizedBox(width: 8),
                        Text(
                          tagText,
                          style: const TextStyle(
                            color: Color(0xFF2D5934),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Caption / Content (Made bigger!)
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 19, // Prominent font size
                      color: Color(0xFF191C1A),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image (Made bigger!)
                  if (finalImageUrl != null && finalImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        finalImageUrl,
                        width: double.infinity,
                        fit: BoxFit.fitWidth, // Make it expand naturally
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFEA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.image_not_supported, size: 48, color: Color(0xFFC2C9BB)),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFEA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.image, size: 48, color: Color(0xFFC2C9BB)),
                    ),
                  const SizedBox(height: 20),

                  // Stats section (Likes, comments counts)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
                        bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$_likesCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF191C1A)),
                        ),
                        const Text(
                          ' Upvotes',
                          style: TextStyle(color: Color(0xFF72796E), fontSize: 15),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '$_downvotesCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF191C1A)),
                        ),
                        const Text(
                          ' Downvotes',
                          style: TextStyle(color: Color(0xFF72796E), fontSize: 15),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '$_commentsCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF191C1A)),
                        ),
                        const Text(
                          ' Comments',
                          style: TextStyle(color: Color(0xFF72796E), fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  // Interactive Action buttons (Upvote, Downvote, Focus Comment)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.arrow_circle_up : Icons.arrow_circle_up_outlined,
                            color: _isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                            size: 26,
                          ),
                          onPressed: _toggleLike,
                        ),
                        IconButton(
                          icon: Icon(
                            _isDownvoted ? Icons.arrow_circle_down : Icons.arrow_circle_down_outlined,
                            color: _isDownvoted ? const Color(0xFFBA1A1A) : const Color(0xFF42493E),
                            size: 26,
                          ),
                          onPressed: _toggleDownvote,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFF42493E),
                            size: 24,
                          ),
                          onPressed: () {
                            _commentFocusNode.requestFocus();
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 16),

                  // Inline Comments List Header
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF154212),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Inline Comments list
                  if (_isLoadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: Color(0xFF154212)),
                      ),
                    )
                  else if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No comments yet. Share your thoughts below!',
                        style: TextStyle(color: Color(0xFF72796E), fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final author = comment['author_name'] ?? 'Unknown User';
                        final body = comment['content'] ?? '';
                        final cTime = comment['created_at'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFECEFEA),
                                backgroundImage: comment['profile_pic_url'] != null
                                    ? NetworkImage(comment['profile_pic_url'])
                                    : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            author,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF191C1A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          _formatRelativeTime(cTime),
                                          style: const TextStyle(
                                            color: Color(0xFF72796E),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF42493E),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom Input Field sticking to the bottom for inline comments
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Post your comment...',
                      hintStyle: const TextStyle(color: Color(0xFF72796E)),
                      filled: true,
                      fillColor: const Color(0xFFF1F3EE),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF154212)),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
