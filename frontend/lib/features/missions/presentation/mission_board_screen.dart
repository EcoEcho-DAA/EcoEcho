import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

                    if (missions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.assignment_turned_in_outlined, size: 60, color: Color(0xFF72796E)),
                              SizedBox(height: 12),
                              Text(
                                'No daily missions available right now!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
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
                        itemCount: missions.length,
                        itemBuilder: (context, index) {
                          final mission = missions[index];
                          return _buildMissionCard(context, mission);
                        },
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFC2C9BB).withOpacity(0.4),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: const Color(0xFF154212).withOpacity(0.08),
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

            // Completion check action
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully completed "$title"! Earned +$xpReward XP!'),
                    backgroundColor: const Color(0xFF154212),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF154212),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Complete',
                style: TextStyle(
                  fontSize: 11,
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
