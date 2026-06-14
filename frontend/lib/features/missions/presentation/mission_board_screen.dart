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
      create: (context) => MissionsBloc()..add(FetchDailyMissions()),
      child: const MissionBoardView(),
    );
  }
}

class MissionBoardView extends StatelessWidget {
  const MissionBoardView({super.key});

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
        child: DefaultTabController(
          length: 2,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Missions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF154212),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF154212)),
                          onPressed: () {
                            context.read<MissionsBloc>().add(FetchDailyMissions());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Complete tasks to earn XP rewards and grow your eco-impact.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF72796E),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const TabBar(
                      labelColor: Color(0xFF154212),
                      unselectedLabelColor: Color(0xFF72796E),
                      indicatorColor: Color(0xFF154212),
                      indicatorWeight: 3.0,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                      tabs: [
                        Tab(text: 'Ongoing'),
                        Tab(text: 'Completed'),
                      ],
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
                                  context.read<MissionsBloc>().add(FetchDailyMissions());
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
                      final missions = state.missions;
                      final analytics = state.analytics;

                      final ongoingMissions = missions.where((m) => m['completed_at'] == null).toList();
                      final completedMissions = missions.where((m) => m['completed_at'] != null).toList();

                      return Column(
                        children: [
                          _buildAnalyticsHeader(analytics),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildMissionsTabList(context, ongoingMissions, false),
                                _buildMissionsTabList(context, completedMissions, true),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionsTabList(BuildContext context, List<dynamic> list, bool isCompleted) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted ? Icons.check_circle_outline : Icons.assignment_outlined,
                size: 60,
                color: const Color(0xFF72796E),
              ),
              const SizedBox(height: 12),
              Text(
                isCompleted ? 'No completed missions yet!' : 'No ongoing missions left!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF42493E),
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MissionsBloc>().add(FetchDailyMissions());
      },
      color: const Color(0xFF154212),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildMissionCard(context, list[index]);
        },
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
          context.read<MissionsBloc>().add(FetchDailyMissions());
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
              child: const Icon(
                Icons.energy_savings_leaf,
                color: Color(0xFF154212),
                size: 24,
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
}
