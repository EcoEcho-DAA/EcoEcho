import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../../../core/network/api_service.dart';
import '../../../profile/presentation/profile_screen.dart';
import 'post_detail_screen.dart';
import 'preview_screen.dart';
import 'camera_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCommunityFeed = true;
  late Future<List<dynamic>> _feedFuture;
  late Future<List<dynamic>> _friendsFeedFuture;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserUid;
  String? _currentUsername;

  int _notificationCount = 0;
  List<dynamic> _pendingRequests = [];
  List<dynamic> _appNotifications = [];

  @override
  void initState() {
    super.initState();
    _feedFuture = _fetchFeed();
    _friendsFeedFuture = _fetchFriendsFeed();
    _fetchNotificationsAndRequests();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await ApiService.get('/api/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentUserUid = data['uid'];
          _currentUsername = data['username'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching current user info: $e');
    }
  }

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    String timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }
    final name = _currentUsername ?? 'Eco Warrior';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        'Good $timeOfDay, $name !',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF154212),
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  void _selectImageSource(BuildContext context, {int? missionId, int? categoryId, bool isProfilePicMode = false, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF154212)),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final cameras = await availableCameras();
                if (!context.mounted) return;
                final uploadSuccess = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      cameras: cameras,
                      missionId: missionId,
                      categoryId: categoryId,
                      isProfilePicMode: isProfilePicMode,
                    ),
                  ),
                );
                if (uploadSuccess == true && onSuccess != null) {
                  onSuccess();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF154212)),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(context, ImageSource.gallery, missionId, categoryId, isProfilePicMode, onSuccess);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
    int? missionId,
    int? categoryId,
    bool isProfilePicMode,
    VoidCallback? onSuccess,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (!context.mounted) return;

      final uploadSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            imageBytes: bytes,
            missionId: missionId,
            categoryId: categoryId,
            isProfilePicMode: isProfilePicMode,
          ),
        ),
      );

      if (uploadSuccess == true && onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
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
                      backgroundImage: buddy['profile_pic_url'] != null
                          ? NetworkImage(buddy['profile_pic_url'])
                          : null,
                      child: buddy['profile_pic_url'] == null
                          ? Text(
                              buddy['username'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
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

  Future<void> _fetchNotificationsAndRequests() async {
    try {
      final requestsRes = await ApiService.get('/api/friends/requests');
      final notificationsRes = await ApiService.get('/api/notifications');

      if (requestsRes.statusCode == 200 && notificationsRes.statusCode == 200) {
        final pending = jsonDecode(requestsRes.body) as List<dynamic>;
        final notifications = jsonDecode(notificationsRes.body) as List<dynamic>;

        int unreadNotifsCount = notifications.where((n) => n['is_read'] == false).length;
        int totalUnread = pending.length + unreadNotifsCount;

        if (mounted) {
          setState(() {
            _pendingRequests = pending;
            _appNotifications = notifications;
            _notificationCount = totalUnread;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications/requests: $e');
    }
  }

  Future<List<dynamic>> _fetchFriendsFeed() async {
    final response = await ApiService.get('/api/feed/friends');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load friends feed');
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

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 2,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : const Color(0xFFF8FAF5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: TabBar(
                          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212),
                          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : const Color(0xFF72796E),
                          indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212),
                          tabs: [
                            Tab(
                              icon: Icon(Icons.person_add_outlined),
                              text: 'Buddy Requests',
                            ),
                            Tab(
                              icon: Icon(Icons.notifications_none_outlined),
                              text: 'Notifications',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildFriendRequestsTab(context, setModalState),
                            _buildAppNotificationsTab(context, setModalState),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendRequestsTab(BuildContext modalContext, StateSetter setModalState) {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Color(0xFF72796E)),
              SizedBox(height: 16),
              Text(
                'No pending requests',
                style: TextStyle(color: Color(0xFF72796E), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final requesterName = request['requester_name'] ?? 'Eco Warrior';
        final requesterUid = request['requester_uid'];
        final timeStr = request['created_at'];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF154212),
                radius: 20,
                backgroundImage: request['profile_pic_url'] != null
                    ? NetworkImage(request['profile_pic_url'])
                    : null,
                child: request['profile_pic_url'] == null
                    ? Text(
                        requesterName.isNotEmpty ? requesterName[0].toUpperCase() : 'E',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      _formatRelativeTime(timeStr),
                      style: const TextStyle(color: Color(0xFF72796E), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Color(0xFF154212)),
                onPressed: () async {
                  await _handleRequestAction(modalContext, requesterUid, 'accept', setModalState);
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Color(0xFFBA1A1A)),
                onPressed: () async {
                  await _handleRequestAction(modalContext, requesterUid, 'decline', setModalState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRequestAction(BuildContext modalContext, String requesterUid, String action, StateSetter setModalState) async {
    final url = '/api/friends/$action';
    try {
      final res = await ApiService.post(url, {'requesterUid': requesterUid});
      if (res.statusCode == 200) {
        await _fetchNotificationsAndRequests();
        if (modalContext.mounted) {
          setModalState(() {});
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Buddy request ${action}ed successfully!'),
              backgroundColor: action == 'accept' ? const Color(0xFF154212) : const Color(0xFFBA1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling request action: $e');
    }
  }

  Widget _buildAppNotificationsTab(BuildContext modalContext, StateSetter setModalState) {
    if (_appNotifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF72796E)),
              SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(color: Color(0xFF72796E), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _appNotifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notif = _appNotifications[index];
        final id = notif['id'];
        final title = notif['title'] ?? 'Notification';
        final message = notif['message'] ?? '';
        final isRead = notif['is_read'] == true;
        final type = notif['type'] ?? 'info';
        final timeStr = notif['created_at'];

        IconData typeIcon = Icons.notifications;
        Color iconColor = const Color(0xFF154212);

        if (type == 'like') {
          typeIcon = Icons.favorite;
          iconColor = const Color(0xFFBA1A1A);
        } else if (type == 'comment') {
          typeIcon = Icons.comment;
          iconColor = const Color(0xFF154212);
        } else if (type == 'promotion') {
          typeIcon = Icons.stars;
          iconColor = Colors.orange;
        } else if (type == 'friend_request') {
          typeIcon = Icons.person_add;
          iconColor = Colors.blue;
        } else if (type == 'friend_accepted') {
          typeIcon = Icons.people;
          iconColor = const Color(0xFF154212);
        }

        return InkWell(
          onTap: () async {
            if (!isRead) {
              try {
                final res = await ApiService.post('/api/notifications/$id/read', {});
                if (res.statusCode == 200) {
                  await _fetchNotificationsAndRequests();
                  if (modalContext.mounted) {
                    setModalState(() {});
                  }
                }
              } catch (e) {
                debugPrint('Error marking notification as read: $e');
              }
            }
          },
          child: Container(
            color: isRead ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.1) : const Color(0xFF154212).withOpacity(0.05)),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              children: [
                Icon(typeIcon, color: iconColor, size: 24),
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
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            _formatRelativeTime(timeStr),
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : const Color(0xFF72796E), fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isRead ? (Theme.of(context).brightness == Brightness.dark ? Colors.white60 : const Color(0xFF72796E)) : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
      _friendsFeedFuture = _fetchFriendsFeed();
    });
    _fetchNotificationsAndRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leadingWidth: 56,
        leading: _isSearching
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF154212)),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              )
            : IconButton(
                icon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF154212)),
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
            : Image.asset(
                'assets/images/eelogo.png',
                height: 28,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'EcoEcho',
                  style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
                ),
              ),
        centerTitle: !_isSearching,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Color(0xFF154212)),
                onPressed: _showNotificationsDialog,
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
          _buildGreetingHeader(),
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
                        currentUserUid: _currentUserUid,
                        onDelete: _refreshFeed,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ] else ...[
            FutureBuilder<List<dynamic>>(
              future: _friendsFeedFuture,
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
                          Text('Failed to load buddies feed: ${snapshot.error}'),
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
                      child: Text('No posts from buddies yet. Add some buddies!'),
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
                        currentUserUid: _currentUserUid,
                        onDelete: _refreshFeed,
                      ),
                    );
                  }).toList(),
                );
              },
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFC2C9BB).withOpacity(0.3)),
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
          Text(
            'Log Green Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload a photo to earn XP and inspire the community.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _selectImageSource(context, onSuccess: () {
              setState(() {
                _feedFuture = _fetchFeed();
                _friendsFeedFuture = _fetchFriendsFeed();
              });
            }),
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Upload Proof', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212),
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
        border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFC2C9BB).withOpacity(0.3))),
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
                      color: _isCommunityFeed ? (Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212)) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isCommunityFeed 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212)) 
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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
                      color: !_isCommunityFeed ? (Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212)) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Buddies',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isCommunityFeed 
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212)) 
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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
  final String? currentUserUid;
  final VoidCallback? onDelete;

  const PostCard({
    Key? key,
    required this.postData,
    this.finalImageUrl,
    this.currentUserUid,
    this.onDelete,
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

  Future<void> _deletePost() async {
    final bool? confirm1 = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Post?',
          style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this post? This will reverse the XP you earned from this post and any associated mission.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!mounted) return;

    final bool? confirm2 = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Confirm Deletion (Step 2 of 2)',
          style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is final and permanent. Are you absolutely certain you want to proceed?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Yes, Delete Permanently'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final postId = widget.postData['id'];
      final response = await ApiService.delete('/api/posts/$postId');
      if (response.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully!'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      } else {
        final err = jsonDecode(response.body);
        messenger.showSnackBar(
          SnackBar(
            content: Text(err['error'] ?? 'Failed to delete post'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(postData: widget.postData),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFC2C9BB).withOpacity(0.3)),
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
                    CircleAvatar(
                      backgroundColor: const Color(0xFFECEFEA),
                      radius: 20,
                      backgroundImage: NetworkImage(
                        widget.postData['profile_pic_url'] ?? 'https://cgchzvlunkatpjvpuluz.supabase.co/storage/v1/object/public/post-images/avatar-placeholder.png'
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        Text(
                          _formatRelativeTime(widget.postData['created_at']),
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E), fontSize: 12),
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
                  if (widget.currentUserUid != null && widget.postData['author_uid'] == widget.currentUserUid)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 20),
                      onPressed: _deletePost,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    )
                  else
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
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B2F1F) : const Color(0xFFE7E9E4),
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
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : const Color(0xFF2D5934), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
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
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : const Color(0xFFECEFEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image_not_supported, size: 48, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : const Color(0xFFC2C9BB)),
                ),
              ),
            )
          else
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : const Color(0xFFECEFEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.image, size: 48, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : const Color(0xFFC2C9BB)),
            ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFC2C9BB).withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.arrow_circle_up : Icons.arrow_circle_up_outlined,
                      color: isLiked ? const Color(0xFF00C853) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
                      size: isLiked ? 25 : 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      likesCount.toString(),
                      style: TextStyle(
                        color: isLiked ? const Color(0xFF00C853) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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
                      color: isDownvoted ? const Color(0xFFBA1A1A) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      downvotesCount.toString(),
                      style: TextStyle(
                        color: isDownvoted ? const Color(0xFFBA1A1A) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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
                    Icon(Icons.chat_bubble_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      commentsCount.toString(),
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    final bool? confirm1 = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Comment?',
          style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!mounted) return;

    final bool? confirm2 = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Confirm Deletion (Step 2 of 2)',
          style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is final and permanent. Are you absolutely certain you want to proceed?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Yes, Delete Permanently'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    try {
      final response = await ApiService.delete('/api/comments/$commentId');
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFFC2C9BB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF154212)),
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
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFECEFEA),
                            backgroundImage: NetworkImage(
                              comment['profile_pic_url'] ?? 'https://cgchzvlunkatpjvpuluz.supabase.co/storage/v1/object/public/post-images/avatar-placeholder.png'
                            ),
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
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
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
                                  style: TextStyle(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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
                        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : const Color(0xFFECEFEA),
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
                          icon: Icon(Icons.send, color: Theme.of(context).brightness == Brightness.dark ? Colors.green : const Color(0xFF154212)),
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
                color: isLiked ? const Color(0xFF00C853) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                likesCount.toString(),
                style: TextStyle(
                  color: isLiked ? const Color(0xFF00C853) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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
                color: isDownvoted ? const Color(0xFFBA1A1A) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                downvotesCount.toString(),
                style: TextStyle(
                  color: isDownvoted ? const Color(0xFFBA1A1A) : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF42493E)),
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