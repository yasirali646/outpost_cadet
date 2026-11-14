import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/services/mission_session.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final catalogAsync = ref.watch(contentCatalogProvider);
    final starGoal = 20;
    final stars = progress.totalStars.clamp(0, starGoal);

    return Scaffold(
      body: MarsBackdrop(
        dim: 0.35,
        child: SafeArea(
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (catalog) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final lockupH = (constraints.maxHeight * 0.28)
                      .clamp(110.0, 200.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  OcAssets.avatarCadet,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'CADET LVL 2',
                                style: TextStyle(
                                  color: OcTokens.sand,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => context.push('/journal'),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: OcTokens.bone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Image.asset(
                            OcAssets.titleLockup,
                            height: lockupH,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 12),
                          OcPanel(
                            padding:
                                const EdgeInsets.fromLTRB(12, 12, 14, 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    OcAssets.emblem,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CADET',
                                        style: TextStyle(
                                          fontFamily: OcTokens.bodyFamily,
                                          color: OcTokens.sand,
                                          fontSize: 11,
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '$stars / $starGoal STARS',
                                        style: const TextStyle(
                                          fontFamily: OcTokens.bodyFamily,
                                          color: OcTokens.bone,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      OcAnimatedMeter(
                                        value: stars / starGoal,
                                        color: OcTokens.rust,
                                        minHeight: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$stars',
                                  style: const TextStyle(
                                    fontFamily: OcTokens.displayFamily,
                                    color: OcTokens.bone,
                                    fontSize: 36,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: lockupH > 160 ? 28 : 16),
                          OcPrimaryCta(
                            label: 'Start Mission',
                            sublabel: "Begin today's challenge",
                            boneStyle: true,
                            onPressed: () {
                              OcHaptics.tap();
                              if (!progress.onboardingDone) {
                                context.push('/onboarding');
                              } else {
                                context.push('/missions');
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                OcHaptics.tap();
                                final tutorialList = catalog.missions
                                    .where((m) => m.isTutorial);
                                final tutorial = tutorialList.isEmpty
                                    ? null
                                    : tutorialList.first;
                                if (tutorial != null) {
                                  ref
                                      .read(missionSessionProvider.notifier)
                                      .startMission(tutorial);
                                  context.push('/build');
                                } else {
                                  context.push('/missions');
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                  OcTokens.radiusMd),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: OcTokens.panelSolid
                                      .withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(
                                      OcTokens.radiusMd),
                                  border: Border.all(
                                      color: OcTokens.panelBorder),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 14, 10, 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: OcTokens.spaceBlack
                                              .withValues(alpha: 0.55),
                                          border: Border.all(
                                            color: OcTokens.bone
                                                .withValues(alpha: 0.55),
                                            width: 1.2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.school_outlined,
                                          color: OcTokens.bone,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'CADET TRAINING',
                                              style: TextStyle(
                                                fontFamily:
                                                    OcTokens.bodyFamily,
                                                color: OcTokens.bone,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.0,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 3),
                                            Text(
                                              'Build skills. Explore Mars. Complete challenges.',
                                              style: TextStyle(
                                                fontFamily:
                                                    OcTokens.bodyFamily,
                                                color: OcTokens.sand,
                                                fontSize: 12,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: OcTokens.bone,
                                        size: 26,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${catalog.missions.length} missions · ages 7–12',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: OcTokens.sand.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
