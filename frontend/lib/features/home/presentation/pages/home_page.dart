import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;
  bool _isCommunityFeed = true;

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
            _buildPostCard(
              name: 'Juan D.',
              timeLocation: 'Quezon City • 2h ago',
              xp: '+50 XP',
              tagIcon: Icons.park,
              tagText: 'Tree Planting',
              tagColor: const Color(0xFF2D5934),
              tagBgColor: const Color(0xFFE7E9E4),
              content: 'Planted 5 new saplings at the local community garden this morning! Feeling hopeful for a greener future. 🌱\n\n#Reforest #GreenLiving #EcoEcho',
              likes: '24',
              comments: '5',
            ),
            const SizedBox(height: 16),
            _buildPostCard(
              name: 'Elena M.',
              timeLocation: 'Makati City • 5h ago',
              xp: '+30 XP',
              tagIcon: Icons.directions_bike,
              tagText: 'Sustainable Transport',
              tagColor: const Color(0xFF79574C),
              tagBgColor: const Color(0xFFFED0C1).withOpacity(0.3),
              content: 'Biked to work today! Saved on gas and got my morning cardio in. Highly recommend taking the scenic route.\n\n#EcoFriendly #Biking #ZeroEmissions',
              likes: '112',
              comments: '18',
              isLiked: true,
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

  Widget _buildPostCard({
    required String name,
    required String timeLocation,
    required String xp,
    required IconData tagIcon,
    required String tagText,
    required Color tagColor,
    required Color tagBgColor,
    required String content,
    required String likes,
    required String comments,
    bool isLiked = false,
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
                      Text(
                        timeLocation,
                        style: const TextStyle(color: Color(0xFF42493E), fontSize: 12),
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
                    Text(
                      xp,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
              color: tagBgColor,
              border: Border.all(color: tagColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tagIcon, size: 16, color: tagColor),
                const SizedBox(width: 6),
                Text(
                  tagText,
                  style: TextStyle(color: tagColor, fontSize: 12, fontWeight: FontWeight.w600),
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
              Icon(
                isLiked ? Icons.eco : Icons.eco_outlined,
                color: isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                likes,
                style: TextStyle(
                  color: isLiked ? const Color(0xFF154212) : const Color(0xFF42493E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF42493E), size: 22),
              const SizedBox(width: 8),
              Text(
                comments,
                style: const TextStyle(color: Color(0xFF42493E), fontWeight: FontWeight.w600, fontSize: 12),
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