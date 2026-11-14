import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/services/mission_session.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  static const _glossary = [
    (
      title: 'Life support',
      body:
          'Air, water, and habitat systems that keep the crew alive. Recyclers recover supplies instead of shipping everything from Earth.',
      asset: OcAssets.life,
    ),
    (
      title: 'Radiation shielding',
      body:
          'Protection from solar particle events and cosmic rays. Covering habitats with Martian soil (regolith) is one studied approach.',
      asset: OcAssets.shieldRes,
    ),
    (
      title: 'Power',
      body:
          'Solar arrays make electricity; batteries store it. Dust storms can cut solar output for many sols.',
      asset: OcAssets.power,
    ),
    (
      title: 'Food production',
      body:
          'Greenhouses grow food but need mass, water, and power. NASA studies plant growth on the ISS for future deep-space crews.',
      asset: OcAssets.food,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final catalog = ref.watch(contentCatalogProvider).valueOrNull;
    final unlocked = progress.unlockedFactIds;

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        dim: 0.4,
        child: SafeArea(
          child: Column(
            children: [
              const OcPageHeader(subtitle: 'MISSION JOURNAL'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    OcPanel(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          OcAssetIcon(OcAssets.book, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FIELD NOTES',
                                  style: TextStyle(
                                    color: OcTokens.sand,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                Text(
                                  '${unlocked.length} NASA fact cards unlocked',
                                  style: const TextStyle(
                                    color: OcTokens.bone,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const OcSectionLabel('Systems glossary'),
                    const SizedBox(height: 8),
                    ..._glossary.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OcPanel(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OcAssetIcon(g.asset, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.title.toUpperCase(),
                                      style: const TextStyle(
                                        color: OcTokens.bone,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      g.body,
                                      style: TextStyle(
                                        color: OcTokens.sand
                                            .withValues(alpha: 0.95),
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const OcSectionLabel('Unlocked NASA facts'),
                    const SizedBox(height: 8),
                    if (catalog == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: OcTokens.rust),
                        ),
                      )
                    else if (unlocked.isEmpty)
                      OcPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Journal empty',
                              style: TextStyle(
                                color: OcTokens.bone,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Complete a mission debrief to unlock fact cards with NASA sources.',
                              style: TextStyle(
                                color: OcTokens.sand,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OcPrimaryCta(
                              label: 'GO TO MISSIONS',
                              onPressed: () {
                                OcHaptics.tap();
                                context.go('/missions');
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      ...unlocked.map((id) {
                        final f = catalog.factById(id);
                        if (f == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OcPanel(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    OcAssetIcon(
                                      OcAssets.debriefLightbulb,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        f.title,
                                        style: const TextStyle(
                                          color: OcTokens.bone,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  f.body,
                                  style: TextStyle(
                                    color: OcTokens.sand.withValues(alpha: 0.95),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Source: ${f.sourceTitle}',
                                  style: const TextStyle(
                                    color: OcTokens.rust,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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
