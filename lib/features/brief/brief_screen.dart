import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/models/models.dart';
import 'package:outpost_cadet/services/mission_session.dart';
import 'package:outpost_cadet/services/nasa_weather.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

final selectedMissionIdProvider = StateProvider<String?>((ref) => 'tutorial');

class BriefScreen extends ConsumerWidget {
  const BriefScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final progress = ref.watch(progressControllerProvider);
    final selectedId = ref.watch(selectedMissionIdProvider);

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        imageAsset: OcAssets.marsBgBrief,
        dim: 0.5,
        child: SafeArea(
          bottom: false,
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (catalog) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BriefHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                      children: [
                        Text(
                          'MISSION BRIEF',
                          style: TextStyle(
                            fontFamily: OcTokens.displayFamily,
                            color: OcTokens.bone,
                            fontSize: 34,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontFamily: OcTokens.bodyFamily,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: 'Every mission builds your skills. ',
                                style: TextStyle(color: OcTokens.sand),
                              ),
                              TextSpan(
                                text: 'Choose your path.',
                                style: TextStyle(
                                  color: OcTokens.rust,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _SpaceWeatherBanner(),
                        const SizedBox(height: 12),
                        ...catalog.missions.map((m) {
                          final selected = (selectedId ?? 'tutorial') == m.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MissionCard(
                              mission: m,
                              selected: selected,
                              bestStars:
                                  progress.bestStarsByMission[m.id] ?? 0,
                              onTap: () {
                                ref
                                    .read(selectedMissionIdProvider.notifier)
                                    .state = m.id;
                              },
                              onStart: () => _startMission(
                                context,
                                ref,
                                m,
                                progress.onboardingDone,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startMission(
    BuildContext context,
    WidgetRef ref,
    MissionDef mission,
    bool onboardingDone,
  ) async {
    final weather = ref.read(spaceWeatherProvider).valueOrNull;
    ref
        .read(missionSessionProvider.notifier)
        .startMission(mission, weather: weather);
    if (!onboardingDone) {
      await ref.read(progressControllerProvider.notifier).completeOnboarding();
    }
    if (context.mounted) context.push('/build');
  }
}

class _SpaceWeatherBanner extends ConsumerWidget {
  const _SpaceWeatherBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(spaceWeatherProvider);
    return async.when(
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xE6141216),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OcTokens.panelBorder),
        ),
        child: const Text(
          'Checking NASA space weather…',
          style: TextStyle(color: OcTokens.sand, fontSize: 12),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (brief) {
        final tint = switch (brief.tier) {
          SpaceWeatherTier.quiet => OcTokens.life,
          SpaceWeatherTier.active => OcTokens.warn,
          SpaceWeatherTier.storm => OcTokens.danger,
        };
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xE6141216),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tint.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: tint, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SPACE WEATHER · ${brief.tierLabel.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: OcTokens.bodyFamily,
                        color: tint,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    brief.attributionChip,
                    style: const TextStyle(
                      color: OcTokens.sand,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${brief.headline}. ${brief.kidBlurb}',
                style: const TextStyle(
                  color: OcTokens.bone,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Source: ${brief.sourceLabel}',
                style: TextStyle(
                  color: OcTokens.sand.withValues(alpha: 0.85),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BriefHeader extends StatelessWidget {
  const _BriefHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: [
          Image.asset(OcAssets.shieldStar, width: 28, height: 28),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OUTPOST CADET',
                  style: TextStyle(
                    fontFamily: OcTokens.displayFamily,
                    color: OcTokens.bone,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'TRAINING COMMAND /////',
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.rust,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          ClipOval(
            child: Image.asset(
              OcAssets.avatarCadetBrief,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.selected,
    required this.bestStars,
    required this.onTap,
    required this.onStart,
  });

  final MissionDef mission;
  final bool selected;
  final int bestStars;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final accent = OcTokens.rust;
    final border = selected
        ? accent
        : OcTokens.panelBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onStart,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xE6141216),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: selected ? 1.6 : 1),
              ),
              child: selected && mission.coachTip != null
                  ? _ExpandedBody(
                      mission: mission,
                      bestStars: bestStars,
                      onStart: onStart,
                    )
                  : _CompactBody(
                      mission: mission,
                      bestStars: bestStars,
                      onStart: onStart,
                    ),
            ),
            if (selected)
              Positioned(
                top: -1,
                left: 12,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: OcTokens.rust,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.mission,
    required this.bestStars,
    required this.onStart,
  });

  final MissionDef mission;
  final int bestStars;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HexMissionIcon(missionId: mission.id),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission.title.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            color: OcTokens.rust,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      _SolsPill(sols: mission.sols, dayWord: mission.dayWord),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _BodyChip(label: mission.bodyLabel),
                      if (mission.siteName != null)
                        _BodyChip(label: mission.siteName!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mission.description,
                    style: const TextStyle(
                      color: OcTokens.sand,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0x33C4B09A)),
        const SizedBox(height: 10),
        _BudgetRow(mission: mission, bestStars: bestStars),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onStart,
            style: TextButton.styleFrom(foregroundColor: OcTokens.rust),
            child: const Text(
              'DEPLOY →',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.mission,
    required this.bestStars,
    required this.onStart,
  });

  final MissionDef mission;
  final int bestStars;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                mission.title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: OcTokens.bodyFamily,
                  color: OcTokens.rust,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _SolsPill(sols: mission.sols, dayWord: mission.dayWord),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HexMissionIcon(missionId: mission.id, size: 52),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mission.description,
                          style: const TextStyle(
                            color: OcTokens.sand,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x33C4B09A)),
                  const SizedBox(height: 10),
                  _BudgetRow(mission: mission, bestStars: bestStars),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: _CoachTipBox(tip: mission.coachTip!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onStart,
            child: const Text('START MISSION'),
          ),
        ),
      ],
    );
  }
}

class _CoachTipBox extends StatelessWidget {
  const _CoachTipBox({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCC0B090C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OcTokens.rust.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  OcAssets.avatarCoach,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'COACH TIP',
                  style: TextStyle(
                    color: OcTokens.rust,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, size: 14, color: OcTokens.rust),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tip,
            textAlign: TextAlign.left,
            softWrap: true,
            style: const TextStyle(
              color: OcTokens.bone,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.mission, required this.bestStars});

  final MissionDef mission;
  final int bestStars;

  String get _massLabel {
    final maxKg = mission.massBudget * 65;
    final loadKg = (mission.massBudget * 40);
    return '${_fmt(loadKg)} kg / ${_fmt(maxKg)} kg';
  }

  String get _powerLabel {
    final maxKw = mission.powerBudget * 0.33;
    final loadKw = mission.powerBudget * 0.23;
    return '${loadKw.toStringAsFixed(1)} kW / ${maxKw.toStringAsFixed(1)} kW';
  }

  String _fmt(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BudgetCell(
            iconAsset: OcAssets.mass,
            label: 'MASS BUDGET',
            value: _massLabel,
          ),
        ),
        Container(width: 1, height: 34, color: const Color(0x33C4B09A)),
        Expanded(
          child: _BudgetCell(
            iconAsset: OcAssets.powerStatus,
            label: 'POWER BUDGET',
            value: _powerLabel,
          ),
        ),
        if (bestStars > 0) ...[
          const SizedBox(width: 6),
          Text(
            '★' * bestStars,
            style: const TextStyle(color: OcTokens.power, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _BudgetCell extends StatelessWidget {
  const _BudgetCell({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  final String iconAsset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: OcTokens.sand.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: OcTokens.bone,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
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

class _BodyChip extends StatelessWidget {
  const _BodyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: OcTokens.rust.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OcTokens.rust.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: OcTokens.bone,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SolsPill extends StatelessWidget {
  const _SolsPill({required this.sols, this.dayWord = 'sol'});

  final int sols;
  final String dayWord;

  @override
  Widget build(BuildContext context) {
    final unit = dayWord.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OcTokens.rust),
      ),
      child: Text(
        '$sols ${unit}S',
        style: const TextStyle(
          color: OcTokens.rust,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _HexMissionIcon extends StatelessWidget {
  const _HexMissionIcon({required this.missionId, this.size = 44});

  final String missionId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexBorderPainter(color: OcTokens.rust),
        child: ClipPath(
          clipper: _HexClipper(),
          child: ColoredBox(
            color: const Color(0xFF141216),
            child: Center(
              child: Image.asset(
                OcAssets.missionIcon(missionId),
                width: size * 0.72,
                height: size * 0.72,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexBorderPainter extends CustomPainter {
  _HexBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _HexClipper().getClip(size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
