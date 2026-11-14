import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/services/oc_audio.dart';
import 'package:outpost_cadet/services/progress_repository.dart';
import 'package:go_router/go_router.dart';

class CadetScreen extends ConsumerWidget {
  const CadetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final level = 1 + (progress.totalStars ~/ 5);
    final xp = (progress.totalStars % 5) * 120;
    const xpMax = 600;
    final xpT = (xp / xpMax).clamp(0.0, 1.0);

    final badges = <({String title, String body, bool unlocked})>[
      (
        title: 'BRIEFING CLEAR',
        body: 'Finished outpost orientation',
        unlocked: progress.onboardingDone,
      ),
      (
        title: 'FIRST STAR',
        body: 'Earned at least 1 mission star',
        unlocked: progress.totalStars >= 1,
      ),
      (
        title: 'MISSION VETERAN',
        body: 'Cleared 2+ missions',
        unlocked: progress.completedMissionIds.length >= 2,
      ),
      (
        title: 'FACT HUNTER',
        body: 'Unlocked 4 NASA fact cards',
        unlocked: progress.unlockedFactIds.length >= 4,
      ),
    ];

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        dim: 0.4,
        child: SafeArea(
          child: Column(
            children: [
              const OcPageHeader(subtitle: 'CADET PROFILE'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    OcPanel(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          OcScaleIn(
                            child: ClipOval(
                              child: Image.asset(
                                OcAssets.avatarCadetBrief,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CADET • LVL $level',
                                  style: const TextStyle(
                                    fontFamily: OcTokens.bodyFamily,
                                    color: OcTokens.bone,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Mars Outpost Trainee',
                                  style: TextStyle(
                                    color: OcTokens.sand,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OcAnimatedMeter(
                                  value: xpT,
                                  color: OcTokens.rust,
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$xp / $xpMax XP',
                                  style: const TextStyle(
                                    color: OcTokens.sand,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OcScaleIn(
                            child: Image.asset(
                              OcAssets.shieldStar,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: OcAudio.instance.muted,
                      builder: (context, muted, _) {
                        return OcPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: !muted,
                            activeThumbColor: OcTokens.bone,
                            activeTrackColor: OcTokens.rust,
                            title: const Text(
                              'MISSION AUDIO',
                              style: TextStyle(
                                color: OcTokens.bone,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.8,
                              ),
                            ),
                            subtitle: Text(
                              muted
                                  ? 'SFX and Mars dusk bed muted'
                                  : 'SFX + dusk ambience on',
                              style: TextStyle(
                                color: OcTokens.sand.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                            secondary: Icon(
                              muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: muted ? OcTokens.sand : OcTokens.rust,
                            ),
                            onChanged: (on) async {
                              OcHaptics.tap();
                              await OcAudio.instance.setMuted(!on);
                              if (!on) return;
                              await OcAudio.instance.startIntroBed(volume: 0.32);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    OcPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OcSectionLabel('Service record'),
                          const SizedBox(height: 10),
                          _RecordRow(
                            label: 'Stars earned',
                            value: '${progress.totalStars}',
                          ),
                          _RecordRow(
                            label: 'Missions cleared',
                            value: '${progress.completedMissionIds.length}',
                          ),
                          _RecordRow(
                            label: 'Fact cards',
                            value: '${progress.unlockedFactIds.length}',
                          ),
                          _RecordRow(
                            label: 'Briefing',
                            value: progress.onboardingDone
                                ? 'Complete'
                                : 'Pending',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const OcSectionLabel('Badges'),
                    const SizedBox(height: 8),
                    ...badges.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OcPanel(
                          highlighted: b.unlocked,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                b.unlocked
                                    ? Icons.verified_rounded
                                    : Icons.lock_outline_rounded,
                                color: b.unlocked
                                    ? OcTokens.rust
                                    : OcTokens.sand.withValues(alpha: 0.55),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title,
                                      style: TextStyle(
                                        color: b.unlocked
                                            ? OcTokens.bone
                                            : OcTokens.sand,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    Text(
                                      b.body,
                                      style: TextStyle(
                                        color: OcTokens.sand
                                            .withValues(alpha: 0.9),
                                        fontSize: 12,
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
                    if (!progress.onboardingDone) ...[
                      const SizedBox(height: 8),
                      OcPrimaryCta(
                        label: 'OPEN BRIEFING',
                        onPressed: () {
                          OcHaptics.tap();
                          context.go('/onboarding');
                        },
                      ),
                    ],
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

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: OcTokens.sand,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: OcTokens.bone,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
