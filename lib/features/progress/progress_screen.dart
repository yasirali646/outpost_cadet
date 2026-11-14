import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/services/mission_session.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final catalog = ref.watch(contentCatalogProvider).valueOrNull;
    final completed = progress.completedMissionIds;
    final facts = progress.unlockedFactIds.length;
    final stars = progress.totalStars;
    final starGoal = 20;
    final starT = (stars / starGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        dim: 0.4,
        child: SafeArea(
          child: Column(
            children: [
              const OcPageHeader(subtitle: 'PROGRESS'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    OcPanel(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          OcScaleIn(
                            child: OcAssetIcon(OcAssets.trophy, size: 56),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const OcSectionLabel('Total stars'),
                                const SizedBox(height: 2),
                                Text(
                                  '$stars',
                                  style: const TextStyle(
                                    fontFamily: OcTokens.displayFamily,
                                    color: OcTokens.bone,
                                    fontSize: 42,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OcAnimatedMeter(
                                  value: starT,
                                  color: OcTokens.rust,
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$stars / $starGoal toward next badge',
                                  style: const TextStyle(
                                    color: OcTokens.sand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'MISSIONS',
                            value: '${completed.length}',
                            asset: OcAssets.missionScout,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            label: 'FACT CARDS',
                            value: '$facts',
                            asset: OcAssets.book,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const OcSectionLabel('Mission record'),
                    const SizedBox(height: 8),
                    if (progress.bestStarsByMission.isEmpty)
                      OcPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'No missions cleared yet.',
                              style: TextStyle(
                                color: OcTokens.bone,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Launch Cadet Training to earn your first stars.',
                              style: TextStyle(
                                color: OcTokens.sand,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OcPrimaryCta(
                              label: 'START TRAINING',
                              onPressed: () {
                                OcHaptics.tap();
                                context.go('/missions');
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      ...progress.bestStarsByMission.entries.map((e) {
                        final mission = catalog?.missions
                            .where((m) => m.id == e.key)
                            .firstOrNull;
                        final title =
                            (mission?.title ?? e.key).toUpperCase();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OcPanel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                OcAssetIcon(
                                  OcAssets.missionTraining,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: OcTokens.bone,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      Text(
                                        e.key,
                                        style: const TextStyle(
                                          color: OcTokens.sand,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '★' * e.value + '☆' * (3 - e.value),
                                  style: const TextStyle(
                                    color: OcTokens.power,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.asset,
  });

  final String label;
  final String value;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return OcPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          OcAssetIcon(asset, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: OcTokens.sand,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: OcTokens.displayFamily,
                    color: OcTokens.bone,
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
