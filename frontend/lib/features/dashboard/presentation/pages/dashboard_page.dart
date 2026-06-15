import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../home/presentation/pages/camera_screen.dart';
import '../../../home/presentation/pages/preview_screen.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../missions/presentation/mission_board_screen.dart';
import '../../../leaderboard/presentation/leaderboard_screen.dart';
import '../../../profile/presentation/profile_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const MissionBoardScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectImageSource(BuildContext context) {
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      cameras: cameras,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF154212)),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            imageBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        elevation: 8,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(child: _buildTabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0)),[cite: 1]
            Expanded(child: _buildTabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Missions', index: 1)),[cite: 1]
            
            // Member's floating camera button layout fully preserved
            Expanded(
              child: GestureDetector(
                onTap: () => _selectImageSource(context),[cite: 1]
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,[cite: 1]
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),[cite: 1]
                      decoration: const BoxDecoration(
                        color: Color(0xFF154212),[cite: 1]
                        shape: BoxShape.circle,[cite: 1]
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),[cite: 1]
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(child: _buildTabItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: 'Leaderboard', index: 2)),[cite: 1]
            Expanded(child: _buildTabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 3)),[cite: 1]
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required IconData activeIcon, required String label, required int index}) {[cite: 1]
    final isSelected = _selectedIndex == index;[cite: 1]
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Adaptive colors instead of light-mode only hardcoded greens and grays
    final color = isSelected 
        ? (isDark ? Colors.green : const Color(0xFF154212)) 
        : (isDark ? const Color(0xFFC2C9BB) : const Color(0xFF72796E));[cite: 1]
    
    return InkWell(
      onTap: () => _onItemTapped(index),[cite: 1]
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),[cite: 1]
        child: Column(
          mainAxisSize: MainAxisSize.min,[cite: 1]
          mainAxisAlignment: MainAxisAlignment.center,[cite: 1]
          children: [
            Icon(isSelected ? activeIcon : icon, color: color),[cite: 1]
            const SizedBox(height: 4),[cite: 1]
            Text(
              label,[cite: 1]
              style: TextStyle(
                color: color,[cite: 1]
                fontSize: 10,[cite: 1]
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,[cite: 1]
              ),
              overflow: TextOverflow.ellipsis,[cite: 1]
              maxLines: 1,[cite: 1]
            ),
          ],
        ),
      ),
    );
      ),
    );
  }
}