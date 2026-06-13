import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for session management
 
import 'ecowrap_trophy_widget.dart';
import 'ecowrap_background.dart';
import 'ecowrap_bento_grid.dart';
import 'ecowrap_share.dart';
import '../../../core/network/api_service.dart';

class EcoWrapStoryScreen extends StatefulWidget {
  const EcoWrapStoryScreen({super.key});
 
  @override
  State<EcoWrapStoryScreen> createState() => _EcoWrapStoryScreenState();
}
 
class _EcoWrapStoryScreenState extends State<EcoWrapStoryScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  Timer? _pageTimer;
  final int _secondsPerPage = 4;
  late AnimationController _progressController;
  final ScreenshotController _screenshotController = ScreenshotController();

  Map<String, dynamic>? _wrappedData;
  bool _isLoading = true;
  String? _error;

  final Color primaryGreen = const Color(0xFF386A2B);
  final Color secondaryBrown = const Color(0xFF885124);
  final Color neutralGray = const Color(0xFF767777);
 
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsPerPage),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchWrappedData());
  }
 
  Future<void> _fetchWrappedData() async {
    try {
      // 1. Pull the securely saved JWT token from local shared preferences
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token'); // Uses the authentication login session key

      // 2. Inject the Bearer token directly inside the ApiService request headers matrix
      final response = await ApiService.get(
        '/api/users/wrapped',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      
      setState(() {
        _wrappedData = {
          'ranking':    data['ranking']    as int,
          'post_count': data['post_count'] as int,
          'tree_count': data['tree_count'] as int,
          'tier_name':  data['tier_name']  as String,
          'total_xp':   data['total_xp']   as int,
        };
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load your EcoWrapped data. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }
 
  void _startTimer() {
    _pageTimer?.cancel();
    _progressController.reset();
    _progressController.forward();
    _pageTimer = Timer(Duration(seconds: _secondsPerPage), () {
      if (_currentPage < _totalPages - 1) {
        _navigate(true);
      } else {
        _pageTimer?.cancel();
      }
    });
  }
 
  void _navigate(bool forward) {
    _pageTimer?.cancel();
    _progressController.stop();

    // guard: don't navigate if PageView isn't built yet
    if (!_pageController.hasClients) return;

    if (forward && _currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (!forward && _currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
 
  void _close() {
    _pageTimer?.cancel();
    _progressController.stop();
    Navigator.of(context).pop();
  }

  String _getTierBadge(String tierName) {
    switch (tierName.toLowerCase()) {
      case 'sprout':
        return 'assets/icons/tier_badge_sprout.png';
      case 'sapling':
        return 'assets/icons/tier_badge_sapling.png';
      case 'ancient tree':
        return 'assets/icons/tier_badge_ancient_tree.png';
      case 'seed':
      default:
        return 'assets/icons/tier_badge_seed.png';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchWrappedData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
 
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0F0),
      body: Center(
        child: Container(
          width: 430,
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              // main content
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (int page) {
                          setState(() => _currentPage = page);
                          _startTimer();
                        },
                        children: [
                          _buildPageOneMilestone(),
                          _buildPageTwoPostLogs(),
                          _buildPageThreeTierUnlock(),
                          _buildPageFourTreePlanting(),
                          _buildPageFiveSummary(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // tap zones for navigation — stops before the top bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 48,
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigate(false),
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigate(true),
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                  ],
                ),
              ),
              // offscreen share card for screenshot capture
              Positioned(
                left: -9999,
                child: Screenshot(
                  controller: _screenshotController,
                  child: EcoWrapShareCard(
                    tierName: _wrappedData?['tier_name'] ?? 'Seed',
                    ranking: _wrappedData?['ranking'] ?? 0,
                    postCount: _wrappedData?['post_count'] ?? 0,
                    treeCount: _wrappedData?['tree_count'] ?? 0,
                    totalXp: _wrappedData?['total_xp'] ?? 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // --- TOP BAR: progress segments + close button ---
 
  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
    child: Row(
      children: [
        Expanded(child: _buildSegmentedProgress()), 
        GestureDetector(    //x button
          onTap: _close,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: neutralGray.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon( Icons.close, size: 18, color: neutralGray),
          ),
        ),
      ],
    ),
  );
 
  // --- PROGRESS BAR ---
 
  Widget _buildSegmentedProgress() => AnimatedBuilder(
    animation: _progressController,
    builder: (context, child) => Row(
      children: List.generate(_totalPages, (index) {
        double fillWidth = (index < _currentPage)
            ? 1.0
            : (index == _currentPage ? _progressController.value : 0.0);
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            decoration: BoxDecoration(
              color: neutralGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillWidth.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
 
  // --- PAGE 1: MILESTONE ---
 
  Widget _buildPageOneMilestone() => EcoWrapBackground(
    page: EcoWrapPage.milestone,
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Text(
            'YOUR 2026 MILESTONE',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder( // Restored to AnimatedBuilder to prevent compile-time deprecation conflicts
                animation: _progressController,
                builder: (context, child) => CustomPaint(
                  size: const Size(200, 200),
                  painter: _ProgressRingPainter(    // animates from 0 → 12% (not 0 → 100%)
                    progress: _progressController.value * ((_wrappedData?['ranking'] ?? 0) / 100),
                    strokeWidth: 10,
                    color: primaryGreen,
                  ),
                ),
              ),
              EcoWrapTrophyWidget(
                percentile: (_wrappedData?['ranking'] ?? 0).toDouble(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Top ${_wrappedData?['ranking'] ?? '0'}%',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
          ),
          Text(
            'of Composters this year!',
            style: TextStyle(color: neutralGray, fontSize: 15),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
 
  // --- PAGE 2: POST LOGS ---
 
  Widget _buildPageTwoPostLogs() => EcoWrapBackground(
    page: EcoWrapPage.postLogs,
    child: _pageWrapper(
      'Consistency is key.',
      '${_wrappedData?['post_count'] ?? 0} Posts shared',
      Icons.share_location,
      secondaryBrown,
    ),
  );
 
  // --- PAGE 3: TIER UNLOCK ---
 
  Widget _buildPageThreeTierUnlock() => EcoWrapBackground(
    page: EcoWrapPage.tierUnlock,
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 100),
          Image.asset(_getTierBadge(_wrappedData?['tier_name'] ?? 'seed'),
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'You achieved the ${_wrappedData?['tier_name'] ?? 'Seed'} Tier!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total Impact: ${_wrappedData?['total_xp'] ?? 0} XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
 
  // --- PAGE 4: TREE PLANTING ---
 
  Widget _buildPageFourTreePlanting() => EcoWrapBackground(
    page: EcoWrapPage.treePlanting,
    child: _pageWrapper(
      'Rooting for change.',
      '${_wrappedData?['tree_count'] ?? 0} Trees planted',
      Icons.park,
      primaryGreen,
    ),
  );
 
  // --- PAGE 5: SUMMARY ---
 
  Widget _buildPageFiveSummary() => EcoWrapBackground(
    page: EcoWrapPage.summary,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 60,
            height: 60,
          ),
          const SizedBox(height: 15),
          const Text(
            'EcoWrapped 2026 Recap',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF386A2B),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: EcoWrapBentoGrid(
              tierName: _wrappedData?['tier_name'] ?? 'Seed',
              ranking: _wrappedData?['ranking'] ?? 0,
              postCount: _wrappedData?['post_count'] ?? 0,
              treeCount: _wrappedData?['tree_count'] ?? 0,
              totalXp: _wrappedData?['total_xp'] ?? 0,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => EcoWrapShare.shareWrapped(
                context: context,
                screenshotController: _screenshotController,
                tierName: _wrappedData?['tier_name'] ?? 'Seed',
                ranking: _wrappedData?['ranking'] ?? 0,
                postCount: _wrappedData?['post_count'] ?? 0,
                treeCount: _wrappedData?['tree_count'] ?? 0,
                totalXp: _wrappedData?['total_xp'] ?? 0,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text(
                'Share Your Story',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
 
  // --- SHARED PAGE WRAPPER ---
 
  Widget _pageWrapper(String title, String stat, IconData icon, Color color) =>
      Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Text(
              title,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    stat,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      );
}
 
// --- PROGRESS RING PAINTER ---
 
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
 
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });
 
  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
 
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
 
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
 
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }
 
  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}