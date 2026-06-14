import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/network/api_service.dart';
import 'ecowrap_web_helper.dart';

class EcoWrapShare {
  static Future<void> downloadPng({
    required BuildContext context,
    required String tierName,
    required int ranking,
    required int postCount,
    required int treeCount,
    required int totalXp,
  }) async {
    try {
      final screenshotController = ScreenshotController();
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        EcoWrapShareCard(
          tierName: tierName,
          ranking: ranking,
          postCount: postCount,
          treeCount: treeCount,
          totalXp: totalXp,
        ),
        pixelRatio: 3.0, // high-res for sharing
        context: context,
      );

      if (kIsWeb) {
        // Trigger browser-native download link flow
        downloadWebPng(imageBytes, 'EcoEcho_Wrapped_2026.png');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EcoWrapped PNG download started!'),
            backgroundColor: Color(0xFF154212),
          ),
        );
      } else {
        // save to temp file on mobile
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/EcoEcho_Wrapped_2026.png').create();
        await file.writeAsBytes(imageBytes);

        final shareText =
            '🌱 My EcoWrapped 2026 on EcoEcho!\n'
            '🏆 Top $ranking% Composter\n'
            '🌳 $treeCount trees planted\n'
            '📋 $postCount posts shared\n'
            '⚡ $totalXp XP earned\n'
            '🎖️ Reached $tierName tier\n\n'
            'Download EcoEcho to track your eco impact! #EcoEcho #EcoWrapped2026';

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'EcoEcho Wrapped 2026',
          text: shareText,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download/share: $e')),
      );
    }
  }

  static Future<void> shareInApp({
    required BuildContext context,
    required String tierName,
    required int ranking,
    required int postCount,
    required int treeCount,
    required int totalXp,
  }) async {
    // Show a loading indicator dialog while preparing the image bytes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF386A2B)),
                SizedBox(height: 16),
                Text('Preparing your EcoWrapped...'),
              ],
            ),
          ),
        ),
      ),
    );

    Uint8List imageBytes;
    try {
      final screenshotController = ScreenshotController();
      imageBytes = await screenshotController.captureFromWidget(
        EcoWrapShareCard(
          tierName: tierName,
          ranking: ranking,
          postCount: postCount,
          treeCount: treeCount,
          totalXp: totalXp,
        ),
        pixelRatio: 3.0,
        context: context,
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // pop loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate EcoWrapped card: $e')),
      );
      return;
    }

    if (context.mounted) Navigator.of(context).pop(); // pop loader

    final initialCaption =
        '🌱 My EcoWrapped 2026 Summary!\n'
        '🏆 Top $ranking% Composter\n'
        '🌳 $treeCount trees planted\n'
        '⚡ $totalXp XP earned\n'
        '🎖️ Reached $tierName tier!';

    if (!context.mounted) return;

    // Show the customized caption editing dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final captionController = TextEditingController(text: initialCaption);
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF8FAF5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Customize Caption',
                style: TextStyle(color: Color(0xFF154212), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageBytes,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Caption input
                    TextField(
                      controller: captionController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF191C1A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFFC2C9BB).withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF386A2B), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF386A2B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);

                          try {
                            final finalCaption = captionController.text.trim();
                            final response = await ApiService.uploadImageBytes(
                              '/api/posts',
                              imageBytes,
                              'EcoEcho_Wrapped_2026_post.png',
                              {
                                'caption': finalCaption,
                                'category_id': '6', // EcoWrapped 2026
                              },
                            );

                            if (response.statusCode == 201) {
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop(); // pop edit dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('EcoWrapped shared to feed successfully! +50 XP'),
                                    backgroundColor: Color(0xFF154212),
                                  ),
                                );
                              }
                            } else {
                              final respBody = await response.stream.bytesToString();
                              throw Exception('Failed to post: $respBody');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to share in community: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Share to Feed', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
                  color: Colors.white.withOpacity(0.2),
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
                color: Colors.white.withOpacity(0.5),
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