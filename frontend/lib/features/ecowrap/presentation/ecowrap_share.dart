import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class EcoWrapShare {
  static Future<void> shareWrapped({
    required BuildContext context,
    required ScreenshotController screenshotController,
    required String tierName,
    required int ranking,
    required int postCount,
    required int treeCount,
    required int totalXp,
  }) async {
    try {
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 3.0, // high-res for sharing
      );
      if (imageBytes == null) return;

      // save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/ecowrapped_2026.png').create();
      await file.writeAsBytes(imageBytes);

      final shareText =
          '🌱 My EcoWrapped 2026!\n'
          '🏆 Top $ranking% Composter\n'
          '🌳 $treeCount trees planted\n'
          '📋 $postCount posts shared\n'
          '⚡ $totalXp XP earned\n'
          '🎖️ Reached $tierName tier\n\n'
          '#EcoEcho #EcoWrapped2026';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share. Please try again.')),
      );
    }
  }
}

class EcoWrapShareCard extends StatelessWidget {
  final String tierName;
  final int ranking;
  final int postCount;
  final int treeCount;
  final int totalXp;

  const EcoWrapShareCard({
    super.key,
    required this.tierName,
    required this.ranking,
    required this.postCount,
    required this.treeCount,
    required this.totalXp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF386A2B), Color(0xFF2E7D52)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'EcoEcho',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '2026',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'My EcoWrapped',
            style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Top $ranking%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Text(
            'of Composters',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _statRow(Icons.park, '$treeCount trees planted'),
          const SizedBox(height: 12),
          _statRow(Icons.share_location, '$postCount posts shared'),
          const SizedBox(height: 12),
          _statRow(Icons.workspace_premium, '$tierName tier achieved'),
          const SizedBox(height: 12),
          _statRow(Icons.bolt, '$totalXp XP earned'),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '#EcoEcho #EcoWrapped2026',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(width: 12),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
    ],
  );
}