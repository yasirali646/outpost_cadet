import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/models/models.dart';
import 'package:outpost_cadet/services/mission_session.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

class DebriefScreen extends ConsumerStatefulWidget {
  const DebriefScreen({super.key});

  @override
  ConsumerState<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends ConsumerState<DebriefScreen> {
  var _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _persist());
  }

  Future<void> _persist() async {
    if (_saved) return;
    final state = ref.read(missionSessionProvider);
    if (state == null) return;
    _saved = true;
    if (state.phase == MissionPhase.won) {
      OcHaptics.success();
    } else {
      OcHaptics.fail();
    }
    final stars = ref.read(missionSessionProvider.notifier).starsEarned();
    if (state.phase == MissionPhase.won) {
      await ref.read(progressControllerProvider.notifier).recordWin(
            missionId: state.mission.id,
            stars: stars,
            factIds: state.unlockedFactIds,
          );
    } else {
      await ref
          .read(progressControllerProvider.notifier)
          .unlockFacts(state.unlockedFactIds);
    }
  }

  static String _gradeLine(int score, bool won) {
    if (!won) return 'OUTPOST DOWN — REVIEW & RETRY';
    if (score >= 85) return 'EXCELLENT WORK, CADET';
    if (score >= 70) return 'GREAT JOB, CADET';
    if (score >= 50) return 'SOLID EFFORT, CADET';
    return 'KEEP TRAINING, CADET';
  }

  static _ScoreBuckets _buckets(DebriefReport report) {
    final survival = report.lines.isNotEmpty ? report.lines[0].points : 0;
    final margin = report.lines.length > 1 ? report.lines[1].points : 0;
    final layout = report.lines.length > 2 ? report.lines[2].points : 0;
    final events = report.lines.length > 3 ? report.lines[3].points : 0;
    final resource = (margin + layout).clamp(0, 40);
    return _ScoreBuckets(
      survival: survival.clamp(0, 40),
      survivalMax: 40,
      resource: resource,
      resourceMax: 40,
      events: events.clamp(0, 20),
      eventsMax: 20,
    );
  }

  static List<_TipCardData> _tipCards(List<String> tips) {
    const catalog = <({String title, String asset, String fallback})>[
      (
        title: 'CONSERVE EARLY',
        asset: OcAssets.debriefDroplet,
        fallback:
            'Save water and power in the first sols so storms do not empty your tanks.',
      ),
      (
        title: 'PRIORITIZE RISKS',
        asset: OcAssets.debriefPeople,
        fallback:
            'On flares and dust, protect the crew first — then recover production.',
      ),
      (
        title: 'CHECK SUPPLIES',
        asset: OcAssets.debriefGear,
        fallback:
            'Watch mass and power budgets before launch. Spares and batteries buy time.',
      ),
    ];
    return List.generate(3, (i) {
      final tip = i < tips.length ? tips[i] : catalog[i].fallback;
      return _TipCardData(
        title: catalog[i].title,
        body: tip,
        asset: catalog[i].asset,
        stars: i == 1 ? 2 : 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionSessionProvider);
    final catalog = ref.watch(contentCatalogProvider).valueOrNull;
    final report = ref.read(missionSessionProvider.notifier).report();

    if (state == null) {
      return Scaffold(
        backgroundColor: OcTokens.spaceBlack,
        body: MarsBackdrop(
          imageAsset: OcAssets.marsBgDebrief,
          child: Center(
            child: FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Home'),
            ),
          ),
        ),
      );
    }

    final won = state.phase == MissionPhase.won;
    final score = report?.totalScore ?? 0;
    final stars = report?.stars ?? 0;
    final buckets = report != null
        ? _buckets(report)
        : const _ScoreBuckets(
            survival: 0,
            survivalMax: 40,
            resource: 0,
            resourceMax: 40,
            events: 0,
            eventsMax: 20,
          );
    final tipCards = _tipCards(report?.tips ?? const []);
    final facts = state.unlockedFactIds
        .map((id) => catalog?.factById(id))
        .whereType<FactCard>()
        .toList();

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        imageAsset: OcAssets.marsBgDebrief,
        dim: 0.42,
        child: SafeArea(
          child: Column(
            children: [
              _DebriefHeader(
                onBack: () {
                  ref.read(missionSessionProvider.notifier).reset();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/missions');
                  }
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  children: [
                    Center(
                      child: OcScaleIn(
                        child: OcAssetIcon(
                          won ? OcAssets.debriefTrophy : OcAssets.debriefShield,
                          size: 72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      won ? 'MISSION SUCCESS' : 'MISSION FAILED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: OcTokens.displayFamily,
                        color: won ? const Color(0xFFE8C56A) : OcTokens.danger,
                        fontSize: 34,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      won
                          ? 'YOU SURVIVED. YOU ADAPTED. YOU LED.'
                          : (state.failReason ??
                                  'The outpost could not continue.')
                              .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: OcTokens.bodyFamily,
                        color: OcTokens.bone,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ScoreHeroCard(
                      score: score,
                      grade: _gradeLine(score, won),
                      buckets: buckets,
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      iconAsset: OcAssets.debriefBars,
                      label: 'SCORE BREAKDOWN',
                    ),
                    const SizedBox(height: 8),
                    _BreakdownRow(
                      asset: OcAssets.debriefShield,
                      title: 'SURVIVAL',
                      body: won
                          ? 'You kept your crew alive through critical events.'
                          : 'Crew endurance across the sols you lasted.',
                      value: buckets.survival,
                      max: buckets.survivalMax,
                      color: OcTokens.life,
                    ),
                    const SizedBox(height: 8),
                    _BreakdownRow(
                      asset: OcAssets.debriefCrate,
                      title: 'RESOURCE MANAGEMENT',
                      body:
                          'Efficient use of oxygen, power, water, and supplies.',
                      value: buckets.resource,
                      max: buckets.resourceMax,
                      color: OcTokens.rust,
                    ),
                    const SizedBox(height: 8),
                    _BreakdownRow(
                      asset: OcAssets.debriefStar,
                      title: 'EVENT DECISIONS',
                      body: 'Smart choices in mission events and challenges.',
                      value: buckets.events,
                      max: buckets.eventsMax,
                      color: OcTokens.good,
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      iconAsset: OcAssets.debriefLightbulb,
                      label: 'NEXT TIME TIPS',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < tipCards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: _TipTile(data: tipCards[i])),
                        ],
                      ],
                    ),
                    if (won && stars > 0) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: OcAssetIcon(OcAssets.debriefStarsRow, size: 48),
                      ),
                      Text(
                        '$stars STAR${stars == 1 ? '' : 'S'} EARNED',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: Color(0xFFE8C56A),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'WHAT YOU LEARNED',
                        style: TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: OcTokens.sand,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...facts.take(2).map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OcPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.title,
                                      style: const TextStyle(
                                        fontFamily: OcTokens.bodyFamily,
                                        color: OcTokens.bone,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      f.body,
                                      style: TextStyle(
                                        fontFamily: OcTokens.bodyFamily,
                                        color: OcTokens.sand
                                            .withValues(alpha: 0.95),
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(missionSessionProvider.notifier).reset();
                          context.go('/dashboard');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OcTokens.bone,
                          side: const BorderSide(color: OcTokens.panelBorder),
                          backgroundColor:
                              OcTokens.panelSolid.withValues(alpha: 0.85),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text(
                          'HOME',
                          style: TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(missionSessionProvider.notifier).reset();
                          context.go('/missions');
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: OcTokens.rustDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text(
                          'TRY AGAIN',
                          style: TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
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

class _ScoreBuckets {
  const _ScoreBuckets({
    required this.survival,
    required this.survivalMax,
    required this.resource,
    required this.resourceMax,
    required this.events,
    required this.eventsMax,
  });

  final int survival;
  final int survivalMax;
  final int resource;
  final int resourceMax;
  final int events;
  final int eventsMax;
}

class _TipCardData {
  const _TipCardData({
    required this.title,
    required this.body,
    required this.asset,
    required this.stars,
  });

  final String title;
  final String body;
  final String asset;
  final int stars;
}

class _DebriefHeader extends StatelessWidget {
  const _DebriefHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OcPageHeader(
      subtitle: 'DEBRIEF',
      leading: OcBackButton(onPressed: onBack),
      trailing: OcAssetIcon(OcAssets.emblem, size: 32),
    );
  }
}

class _ScoreHeroCard extends StatelessWidget {
  const _ScoreHeroCard({
    required this.score,
    required this.grade,
    required this.buckets,
  });

  final int score;
  final String grade;
  final _ScoreBuckets buckets;

  @override
  Widget build(BuildContext context) {
    return OcPanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: OcTokens.displayFamily,
                color: OcTokens.bone,
                fontSize: 42,
                letterSpacing: 1,
              ),
              children: [
                TextSpan(text: '$score'),
                TextSpan(
                  text: ' / 100',
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.sand.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            grade,
            style: const TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.sand,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  asset: OcAssets.debriefShield,
                  label: 'SURVIVAL',
                  value: buckets.survival,
                  max: buckets.survivalMax,
                  color: OcTokens.life,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  asset: OcAssets.debriefCrate,
                  label: 'RESOURCE',
                  value: buckets.resource,
                  max: buckets.resourceMax,
                  color: OcTokens.rust,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  asset: OcAssets.debriefClipboard,
                  label: 'EVENT DECISIONS',
                  value: buckets.events,
                  max: buckets.eventsMax,
                  color: OcTokens.good,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.asset,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String asset;
  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OcAssetIcon(asset, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: OcTokens.bodyFamily,
            color: OcTokens.sand,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          '$value / $max',
          style: const TextStyle(
            fontFamily: OcTokens.bodyFamily,
            color: OcTokens.bone,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: OcAnimatedMeter(
            value: (value / max).clamp(0.0, 1.0),
            color: color,
            minHeight: 4,
            duration: const Duration(milliseconds: 800),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.iconAsset, required this.label});

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OcAssetIcon(iconAsset, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: OcTokens.bodyFamily,
            color: OcTokens.bone,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: OcTokens.panelBorder,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.asset,
    required this.title,
    required this.body,
    required this.value,
    required this.max,
    required this.color,
  });

  final String asset;
  final String title;
  final String body;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OcPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OcAssetIcon(asset, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: OcTokens.bone,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      '$value/$max',
                      style: const TextStyle(
                        fontFamily: OcTokens.bodyFamily,
                        color: OcTokens.bone,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.sand.withValues(alpha: 0.95),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                OcAnimatedMeter(
                  value: (value / max).clamp(0.0, 1.0),
                  color: color,
                  minHeight: 5,
                  duration: const Duration(milliseconds: 900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.data});

  final _TipCardData data;

  @override
  Widget build(BuildContext context) {
    return OcPanel(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        children: [
          OcAssetIcon(data.asset, size: 26),
          const SizedBox(height: 6),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.bone,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.body,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.sand.withValues(alpha: 0.95),
              fontSize: 9,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              data.stars,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: Color(0xFFE8C56A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
