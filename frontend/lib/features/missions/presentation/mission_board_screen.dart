import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../home/presentation/pages/preview_screen.dart';
import '../../home/presentation/pages/camera_screen.dart';
import 'package:camera/camera.dart';
import 'bloc/missions_bloc.dart';
import 'bloc/missions_event.dart';
import 'bloc/missions_state.dart';

class MissionBoardScreen extends StatelessWidget {
  const MissionBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MissionsBloc()..add(FetchAllMissions()),
      child: const MissionBoardView(),
    );
  }
}

class MissionBoardView extends StatefulWidget {
  const MissionBoardView({super.key});

  @override
  State<MissionBoardView> createState() => _MissionBoardViewState();
}

class _MissionBoardViewState extends State<MissionBoardView> {
  bool _showCompletedDailyMissions = false;

  String _formatHumanDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dateTime.month - 1];
      final day = dateTime.day;
      final year = dateTime.year;
      return '$month $day, $year';
    } catch (_) {
      return '';
    }
  }

  String _getMissionIcon(int missionId, {int? categoryId}) {
    if (missionId == 101) return 'assets/icons/mission_tree.png';
    if (missionId == 102) return 'assets/icons/mission_recycling.png';
    if (missionId == 103) return 'assets/icons/mission_community.png';
    if (missionId == 104) return 'assets/icons/mission_plastic.png';
    if (missionId == 105) return 'assets/icons/mission_water.png';
    
    if (categoryId == 1) return 'assets/icons/mission_tree.png'; 
    if (categoryId == 2) return 'assets/icons/mission_community.png';
    if (categoryId == 3) return 'assets/icons/mission_recycling.png';
    if (categoryId == 4) return 'assets/icons/mission_water.png';
    if (categoryId == 5) return 'assets/icons/mission_plastic.png';
    return 'assets/icons/mission_tree.png';
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

  Widget _buildAnalyticsHeader(Map<String, dynamic> analytics) {
    final tier = analytics['tier_name'] ?? 'Tier 1';
    final thisWeek = analytics['xp_week'] ?? 0;
    final thisMonth = analytics['xp_month'] ?? 0;
    final thisYear = analytics['xp_year'] ?? 0;
    final allTime = analytics['total_xp'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF154212), Color(0xFF2E6F27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154212).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XP Earnings Overview',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricBox('This Week', '+$thisWeek'),
              _buildMetricBox('This Month', '+$thisMonth'),
              _buildMetricBox('This Year', '+$thisYear'),
              _buildMetricBox('All-Time', '$allTime'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.0)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A79564B),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Missions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF154212),
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Complete tasks to earn XP and grow your eco-impact.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF72796E),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF154212)),
                    onPressed: () {
                      context.read<MissionsBloc>().add(FetchAllMissions());
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Missions list content
            Expanded(
              child: BlocBuilder<MissionsBloc, MissionsState>(
                builder: (context, state) {
                  if (state is MissionsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF154212),
                      ),
                    );
                  }

                  if (state is MissionsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFFBA1A1A),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<MissionsBloc>().add(FetchAllMissions());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF154212),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is MissionsLoaded) {
                    final dailyMissions = state.dailyMissions;
                    final analytics = state.analytics;
                    final fixedMissions = state.fixedMissions;
                    final prerequisites = state.prerequisites;

                    final ongoingMissions = dailyMissions.where((m) => m['completed_at'] == null).toList();
                    final completedMissions = dailyMissions.where((m) => m['completed_at'] != null).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<MissionsBloc>().add(FetchAllMissions());
                      },
                      color: const Color(0xFF154212),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnalyticsHeader(analytics),
                            
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Daily Missions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF154212), fontFamily: 'Be Vietnam Pro')),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Color(0xFF154212)),
                                    onSelected: (value) {
                                      if (value == 'toggle_completed') {
                                        setState(() {
                                          _showCompletedDailyMissions = !_showCompletedDailyMissions;
                                        });
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      CheckedPopupMenuItem<String>(
                                        value: 'toggle_completed',
                                        checked: _showCompletedDailyMissions,
                                        child: const Text('Show completed missions'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            if (ongoingMissions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Text('No ongoing daily missions left!', style: TextStyle(color: Color(0xFF72796E))),
                              )
                            else
                              ...ongoingMissions.map((m) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildMissionCard(context, m),
                              )),
                              
                            if (_showCompletedDailyMissions && completedMissions.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                                child: Text('Completed Daily Missions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF72796E), fontFamily: 'Be Vietnam Pro')),
                              ),
                              ...completedMissions.map((m) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildMissionCard(context, m),
                              )),
                            ],

                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE2E9DB), thickness: 8),
                            const SizedBox(height: 16),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text('User Missions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF154212), fontFamily: 'Be Vietnam Pro')),
                            ),

                            _buildFixedMissionsBoard(fixedMissions, prerequisites),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, Map<String, dynamic> mission) {
    final title = mission['title'] ?? 'Eco Action';
    final description = mission['description'] ?? 'Take action to save the planet.';
    final xpReward = mission['xp_reward'] ?? 0;
    final missionId = mission['id'];
    final completedAt = mission['completed_at'];
    final isCompleted = completedAt != null;

    int categoryId = 1;
    if (missionId == 1) {
      categoryId = 4; // Energy Saving
    } else if (missionId == 2) {
      categoryId = 4; // Energy Saving
    } else if (missionId == 3) {
      categoryId = 3; // Recycling
    } else if (missionId == 4) {
      categoryId = 1; // Tree Planting
    }

    final VoidCallback navigateToUpload = () {
      if (isCompleted) return;
      _selectImageSource(
        context,
        missionId: missionId,
        categoryId: categoryId,
        onSuccess: () {
          context.read<MissionsBloc>().add(FetchAllMissions());
        },
      );
    };
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFC2C9BB).withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0579564B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                _getMissionIcon(missionId, categoryId: categoryId),
                color: const Color(0xFF154212),
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1A),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF42493E),
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // XP Reward chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF154212).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$xpReward XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF154212),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),

            // Completion check action or Completion Date label
            if (isCompleted)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF154212), size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'Completed on ${_formatHumanDate(completedAt)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF72796E),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: navigateToUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF154212),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: const Size(110, 40),
                ),
                child: const Text(
                  'Upload Photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedMissionsBoard(List<dynamic> missions, List<dynamic> prerequisites) {
    Map<int, dynamic> missionMap = {};
    for(var m in missions) {
      missionMap[m['id']] = m;
    }
    
    bool isCompleted(int id) => missionMap[id]?['completed_at'] != null;
    
    bool isUnlocked(int id) {
       if (id == 101) return true;
       if (id == 102 || id == 103) return isCompleted(101);
       if (id == 104) return isCompleted(102);
       if (id == 105) return isCompleted(103);
       return false;
    }

    Widget buildNode(int id, Color activeColor) {
      final m = missionMap[id];
      if (m == null) return const SizedBox(width: 120, height: 120);
      
      final bool completed = isCompleted(id);
      final bool unlocked = isUnlocked(id);
      final String title = m['title'] ?? '';
      
      IconData _getFixedMissionOriginalIcon(int id) {
        switch (id) {
          case 101: return Icons.eco;
          case 102: return Icons.water_drop;
          case 103: return Icons.park;
          case 104: return Icons.recycling;
          case 105: return Icons.groups;
          default: return Icons.star;
        }
      }
      final IconData originalIcon = _getFixedMissionOriginalIcon(id);

      return GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (sheetContext) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(originalIcon, color: activeColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF154212),
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reward: ${m['xp_reward'] ?? 0} XP',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E6F27),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    m['description'] ?? 'Take action to save the planet.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF42493E),
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (completed)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF154212).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF154212)),
                          SizedBox(width: 8),
                          Text('Mission Completed!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF154212))),
                        ],
                      ),
                    )
                  else if (!unlocked)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock, color: Color(0xFFBA1A1A)),
                          SizedBox(width: 8),
                          Text('Complete previous missions to unlock', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A))),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          int catId = 1;
                          if (id == 102 || id == 104) catId = 3; 
                          else if (id == 103) catId = 2;
                          else if (id == 101) catId = 5;
                          
                          _selectImageSource(
                            context,
                            missionId: id,
                            categoryId: catId, 
                            onSuccess: () {
                              context.read<MissionsBloc>().add(FetchAllMissions());
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF154212),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Upload Photo Proof', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        child: Container(
           width: 120,
           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
           decoration: BoxDecoration(
             color: unlocked ? (completed ? Colors.white : const Color(0xFFF4F6F0)) : Colors.transparent,
             border: Border.all(
               color: completed ? const Color(0xFF154212) : 
                      (unlocked ? const Color(0xFFD3D8CE) : Colors.transparent),
               width: completed ? 2.0 : 1.0,
             ),
             borderRadius: BorderRadius.circular(16),
           ),
           child: Column(
             children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? const Color(0xFF154212) : 
                           (unlocked ? activeColor : const Color(0xFFE7E9E4)),
                  ),
                  child: completed 
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : (unlocked 
                        ? Icon(originalIcon, color: Colors.white, size: 28)
                        : const Icon(Icons.lock_outline, color: Color(0xFFC2C9BB), size: 28)),
                ),
               const SizedBox(height: 12),
               Text(
                 title,
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                   fontFamily: 'Be Vietnam Pro',
                   color: unlocked ? const Color(0xFF154212) : const Color(0xFFC2C9BB),
                 ),
               ),
               if (unlocked && !completed) ...[
                 const SizedBox(height: 8),
                 Container(
                   width: 80,
                   height: 6,
                   decoration: BoxDecoration(
                     color: const Color(0xFFD3D8CE),
                     borderRadius: BorderRadius.circular(3),
                   ),
                   child: Align(
                     alignment: Alignment.centerLeft,
                     child: Container(
                       width: 40,
                       height: 6,
                       decoration: BoxDecoration(
                         color: const Color(0xFF154212),
                         borderRadius: BorderRadius.circular(3),
                       ),
                     ),
                   ),
                 ),
               ],
             ],
           ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(16),
               boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A79564B),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
               ],
             ),
             child: Column(
               children: [
                  Row(
                    children: const [
                      Icon(Icons.account_tree_outlined, color: Color(0xFF154212)),
                      SizedBox(width: 8),
                      Text('Mission Board', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Be Vietnam Pro', color: Color(0xFF154212))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  buildNode(101, const Color(0xFF154212)),
                  
                  CustomPaint(
                    size: const Size(160, 40),
                    painter: TreeLinePainter(),
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          buildNode(102, const Color(0xFF72796E)),
                          CustomPaint(
                            size: const Size(2, 40),
                            painter: VerticalLinePainter(),
                          ),
                          buildNode(104, const Color(0xFF72796E)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          buildNode(103, const Color(0xFF2E6F27)),
                          CustomPaint(
                            size: const Size(2, 40),
                            painter: VerticalLinePainter(),
                          ),
                          buildNode(105, const Color(0xFF72796E)),
                        ],
                      ),
                    ],
                  ),
               ],
             ),
          ),
        ),
      ),
    );
  }
}

class TreeLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF154212)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height / 2);
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    path.moveTo(0, size.height / 2);
    path.lineTo(0, size.height);
    path.moveTo(size.width, size.height / 2);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerticalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC2C9BB)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    double startY = 0;
    while(startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY), Offset(size.width / 2, startY + 4), paint);
      startY += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
