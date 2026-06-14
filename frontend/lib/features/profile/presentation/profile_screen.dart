import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_service.dart';
import '../../ecowrap/presentation/ecowrap_story_screen.dart';
import '../../home/presentation/pages/post_detail_screen.dart';
import '../../home/presentation/pages/preview_screen.dart';
import '../../home/presentation/pages/camera_screen.dart';
import 'dart:typed_data';
import 'settings_view.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _postsFuture;
  List<dynamic> _friendsList = [];

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

  void _showReportAccountDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Report Account',
          style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontFamily: 'Be Vietnam Pro'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us understand what is wrong. Please provide a brief reason for reporting this account:',
              style: TextStyle(fontSize: 14, color: Color(0xFF42493E)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'Reason for report (e.g. spam, inappropriate content...)',
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFBA1A1A))),
                border: OutlineInputBorder(),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Submit Report'),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason for the report.')),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              try {
                final response = await ApiService.post('/api/users/report', {
                  'target_user_uid': widget.userId,
                  'reason': reason,
                });

                if (response.statusCode == 201) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. Thank you for keeping EcoEcho safe.'),
                      backgroundColor: Color(0xFF154212),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final errData = jsonDecode(response.body);
                  messenger.showSnackBar(
                    SnackBar(content: Text(errData['error'] ?? 'Failed to submit report.')),
                  );
                }
              } catch (e) {
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

  String _getTierImagePath(String tierName) {
    final name = tierName.toLowerCase();
    if (name.contains('seedling') || name == 'seed') {
      return 'assets/icons/tier_seed.png';
    } else if (name.contains('sprout')) {
      return 'assets/icons/tier_sprout.png';
    } else if (name.contains('sapling')) {
      return 'assets/icons/tier_sapling.png';
    } else if (name.contains('thriving tree') || name.contains('ancient')) {
      return 'assets/icons/tier_ancient.png';
    }
    return 'assets/icons/tier_seed.png';
  }

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
      final profile = jsonDecode(response.body) as Map<String, dynamic>;
      
      final friendsUrl = '/api/users/${profile['uid']}/friends';
      try {
        final friendsRes = await ApiService.get(friendsUrl);
        if (friendsRes.statusCode == 200) {
          _friendsList = jsonDecode(friendsRes.body) as List<dynamic>;
        }
      } catch (e) {
        debugPrint('Error fetching friends: $e');
      }

      return profile;
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
          if (widget.userId != null)
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, color: Color(0xFFBA1A1A)),
              tooltip: 'Report Account',
              onPressed: _showReportAccountDialog,
            ),
          if (widget.userId == null)
            FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return IconButton(
                    icon: const Icon(Icons.settings, color: Color(0xFF154212)),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsView(userProfile: snapshot.data!),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
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
                        GestureDetector(
                          onTap: widget.userId == null
                              ? () => _selectImageSource(context, isProfilePicMode: true, onSuccess: () {
                                  setState(() {
                                    _profileFuture = _fetchProfileData();
                                  });
                                })
                              : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFFC2C9BB),
                                backgroundImage: data['profile_pic_url'] != null
                                  ? NetworkImage(data['profile_pic_url'])
                                  : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                              ),
                              if (widget.userId == null)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF154212),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
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
                        // Biography Section
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              data['bio'] != null && data['bio'].toString().isNotEmpty
                                  ? data['bio']
                                  : (widget.userId == null
                                      ? 'No bio added yet. Tap "Edit Profile" to add one!'
                                      : 'No bio added.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: data['bio'] == null || data['bio'].toString().isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: const Color(0xFF42493E),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.userId == null) ...[
                          OutlinedButton.icon(
                            onPressed: () => _showEditProfileDialog(data),
                            icon: const Icon(Icons.edit, size: 14, color: Color(0xFF154212)),
                            label: const Text(
                              'Edit Profile',
                              style: TextStyle(fontSize: 12, color: Color(0xFF154212), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF154212)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ] else ...[
                          _buildFriendshipButton(data),
                        ],
                         const SizedBox(height: 32),
                        // Progress Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  _getTierImagePath(tier),
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tier.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF154212),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
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
                _buildEcoWrapBanner(data),
                const SizedBox(height: 24),
                _buildFriendsListSection(),
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
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(postData: post),
                                ),
                              );
                            },
                            child: _buildProfilePostCard(
                              timeLocation: _formatRelativeTime(post['created_at']),
                              tagText: post['tag_text'] ?? 'Activity',
                              content: post['caption'] ?? '',
                              imageUrl: finalImageUrl,
                            ),
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

  void _showEditProfileDialog(Map<String, dynamic> currentData) {
    final usernameController = TextEditingController(text: currentData['username']);
    final cityController = TextEditingController(text: currentData['city']);
    final provinceController = TextEditingController(text: currentData['province']);
    final regionController = TextEditingController(text: currentData['region'] ?? '');
    final bioController = TextEditingController(text: currentData['bio'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit Profile & Bio',
          style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold, fontFamily: 'Be Vietnam Pro'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Color(0xFF154212)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF154212))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  labelStyle: TextStyle(color: Color(0xFF154212)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF154212))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: provinceController,
                decoration: const InputDecoration(
                  labelText: 'Province',
                  labelStyle: TextStyle(color: Color(0xFF154212)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF154212))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regionController,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  labelStyle: TextStyle(color: Color(0xFF154212)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF154212))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Color(0xFF154212)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF154212))),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF154212),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Save'),
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newCity = cityController.text.trim();
              final newProvince = provinceController.text.trim();
              final newRegion = regionController.text.trim();
              final newBio = bioController.text.trim();

              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Username cannot be empty.')),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              try {
                final response = await ApiService.put('/api/users/profile', {
                  'username': newUsername,
                  'city': newCity,
                  'province': newProvince,
                  'region': newRegion,
                  'bio': newBio,
                });

                if (response.statusCode == 200) {
                  navigator.pop();
                  setState(() {
                    _profileFuture = _fetchProfileData();
                  });
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Color(0xFF154212),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update profile (Code: ${response.statusCode})')),
                  );
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error updating profile: $e')),
                );
              }
            },
          ),
        ],
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

  Widget _buildFriendshipButton(Map<String, dynamic> data) {
    final status = data['friendship_status'];
    final initiator = data['friendship_initiator'];
    final otherUid = data['uid'];

    if (status == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: ElevatedButton.icon(
          onPressed: () => _sendFriendRequest(otherUid),
          icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
          label: const Text(
            'Add Buddy',
            style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF154212),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      );
    } else if (status == 'pending') {
      if (initiator == otherUid) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _acceptFriendRequest(otherUid),
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                label: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154212),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _declineFriendRequest(otherUid),
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                label: const Text(
                  'Decline',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_empty, size: 16, color: Color(0xFF72796E)),
            label: const Text(
              'Request Sent',
              style: TextStyle(fontSize: 14, color: Color(0xFF72796E), fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC2C9BB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        );
      }
    } else if (status == 'accepted') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE7E9E4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF154212).withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 16, color: Color(0xFF154212)),
              SizedBox(width: 8),
              Text(
                'Buddies',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF154212),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _sendFriendRequest(String otherUid) async {
    try {
      final response = await ApiService.post('/api/friends/request', {'friendUid': otherUid});
      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _profileFuture = _fetchProfileData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buddy request sent!'),
            backgroundColor: Color(0xFF154212),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['error'] ?? 'Failed to send request'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(String otherUid) async {
    try {
      final response = await ApiService.post('/api/friends/accept', {'requesterUid': otherUid});
      if (response.statusCode == 200) {
        setState(() {
          _profileFuture = _fetchProfileData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buddy request accepted!'),
            backgroundColor: Color(0xFF154212),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['error'] ?? 'Failed to accept request'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _declineFriendRequest(String otherUid) async {
    try {
      final response = await ApiService.post('/api/friends/decline', {'requesterUid': otherUid});
      if (response.statusCode == 200) {
        setState(() {
          _profileFuture = _fetchProfileData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buddy request declined.'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['error'] ?? 'Failed to decline request'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildEcoWrapBanner(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2C11), Color(0xFF1B4D1E), Color(0xFF101B11)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF9DD090).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9DD090), width: 1.5),
              ),
              child: const Icon(Icons.stars_rounded, color: Color(0xFF9DD090), size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EcoWrapped 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore impact milestones and dynamic standing recap!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EcoWrapStoryScreen(userId: data['uid']),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                backgroundColor: const Color(0xFF154212),
                foregroundColor: Colors.white,
              ),
              child: const Icon(Icons.play_arrow_rounded, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsListSection() {
    if (_friendsList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.userId == null ? 'My Buddies (${_friendsList.length})' : 'Buddies (${_friendsList.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1A),
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _friendsList.length,
            itemBuilder: (context, index) {
              final friend = _friendsList[index];
              final String name = friend['username'] ?? 'Eco Warrior';
              final String friendUid = friend['uid']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    if (friendUid.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: friendUid),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFECEFEA),
                        backgroundImage: friend['profile_pic_url'] != null
                            ? NetworkImage(friend['profile_pic_url'])
                            : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF42493E),
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
