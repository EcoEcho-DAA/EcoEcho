import 'package:flutter/material.dart';

class EcoWrapBentoGrid extends StatelessWidget {
  final String tierName;
  final int ranking;
  final int postCount;
  final int treeCount;
  final int totalXp;

  const EcoWrapBentoGrid({
    super.key,
    required this.tierName,
    required this.ranking,
    required this.postCount,
    required this.treeCount,
    required this.totalXp,
  });

  static const _primaryGreen = Color(0xFF386A2B);
  static const _secondaryBrown = Color(0xFF885124);
  static const _neutralGray = Color(0xFF767777);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BentoCard(
          icon: Icons.workspace_premium,
          iconColor: Colors.amber,
          label: 'TIER REACHED',
          value: tierName,
          accent: const Color(0xFFFFF8E1),
        ),
        const SizedBox(height: 8),
        _BentoCard(
          icon: Icons.emoji_events,
          iconColor: _primaryGreen,
          label: 'RANKING',
          value: 'Top $ranking% Composter',
          accent: const Color(0xFFE8F5E1),
        ),
        const SizedBox(height: 8),
        _BentoCard(
          icon: Icons.share_location,
          iconColor: _secondaryBrown,
          label: 'POSTS SHARED',
          value: '$postCount logs',
          accent: const Color(0xFFF5EDE8),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BentoCard(
                icon: Icons.park,
                iconColor: _primaryGreen,
                label: 'TREES',
                value: '$treeCount planted',
                accent: const Color(0xFFE1F0E8),
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoCard(
                icon: Icons.bolt,
                iconColor: _neutralGray,
                label: 'TOTAL XP',
                value: '$totalXp xp',
                accent: const Color(0xFFEAF4FB),
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color accent;
  final bool compact;

  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 10),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Color(0xFF767777),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Color(0xFF767777),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}