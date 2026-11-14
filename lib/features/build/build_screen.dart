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

class BuildScreen extends ConsumerWidget {
  const BuildScreen({super.key});

  static String cellLabel(int cell) {
    final row = OutpostGrid.row(cell) + 1;
    final col = String.fromCharCode('A'.codeUnitAt(0) + OutpostGrid.col(cell));
    return '$row$col';
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(missionSessionProvider);
    final engine = ref.watch(simEngineProvider);
    final catalog = ref.watch(contentCatalogProvider).valueOrNull;
    final selected = ref.watch(selectedModuleProvider);
    final progress = ref.watch(progressControllerProvider);
    final cadetLevel = 1 + (progress.totalStars ~/ 5);

    if (state == null || engine == null || catalog == null) {
      return Scaffold(
        backgroundColor: OcTokens.spaceBlack,
        body: MarsBackdrop(
          imageAsset: OcAssets.marsBgBuild,
          child: Center(
            child: FilledButton(
              onPressed: () => context.go('/missions'),
              child: const Text('Pick a mission'),
            ),
          ),
        ),
      );
    }

    final mass = engine.usedMass(state.moduleCounts);
    final power = engine.usedPowerDraw(state.moduleCounts);
    final placeable =
        catalog.modules.where((m) => !m.required).toList(growable: false);
    final hasBonus = state.layoutBonusNotes.isNotEmpty;
    final ready = mass <= state.mission.massBudget &&
        power <= state.mission.powerBudget;

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        imageAsset: OcAssets.marsBgBuild,
        dim: 0.42,
        child: SafeArea(
          child: Column(
            children: [
              _BuildHeader(
                cadetLevel: cadetLevel,
                onBack: () {
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
                    Row(
                      children: [
                        Expanded(
                          child: _BudgetCard(
                            icon: Icons.fitness_center_rounded,
                            label: 'MASS BUDGET',
                            value:
                                '${_fmt(mass)} / ${_fmt(state.mission.massBudget)} kg',
                            progress: mass / state.mission.massBudget,
                            barColor: OcTokens.good,
                            over: mass > state.mission.massBudget,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BudgetCard(
                            icon: Icons.bolt_rounded,
                            label: 'POWER DRAW',
                            value:
                                '${_fmt(power)} / ${_fmt(state.mission.powerBudget)} W',
                            progress: power / state.mission.powerBudget,
                            barColor: OcTokens.rust,
                            over: power > state.mission.powerBudget,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: OutpostGrid.cellCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemBuilder: (context, cell) {
                          final id = state.placements[cell];
                          final isHabitat = cell == OutpostGrid.habitatCell;
                          return _GridCell(
                            label: cellLabel(cell),
                            moduleId: id,
                            isHabitat: isHabitat,
                            onTap: () {
                              final session =
                                  ref.read(missionSessionProvider.notifier);
                              if (isHabitat) {
                                OcHaptics.empty();
                                return;
                              }
                              if (id != null) {
                                OcHaptics.remove();
                                session.clearCell(cell);
                                return;
                              }
                              final pick = selected;
                              if (pick == null) {
                                OcHaptics.empty();
                                return;
                              }
                              if (!engine.canPlace(state, pick, cell)) {
                                OcHaptics.empty();
                                return;
                              }
                              OcHaptics.place();
                              session.placeModule(pick, cell: cell);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LayoutBonusBanner(
                      notes: state.layoutBonusNotes,
                      active: hasBonus,
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Text(
                          'MODULE PALETTE',
                          style: TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            color: OcTokens.bone,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.6,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.help_outline_rounded,
                          size: 16,
                          color: OcTokens.sand,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: placeable.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == placeable.length) {
                            return _LockedPaletteCard(cadetLevel: cadetLevel);
                          }
                          final mod = placeable[i];
                          final locked = _isLocked(mod.id, cadetLevel);
                          final count = state.moduleCounts[mod.id] ?? 0;
                          final canAdd = !locked && engine.canAfford(state, mod.id);
                          final isSelected = selected == mod.id;
                          final placed = count > 0;
                          return _PaletteCard(
                            module: mod,
                            selected: isSelected,
                            placed: placed,
                            locked: locked,
                            canAdd: canAdd,
                            onTap: locked
                                ? null
                                : () {
                                    OcHaptics.tap();
                                    ref
                                        .read(selectedModuleProvider.notifier)
                                        .state = mod.id;
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Column(
                  children: [
                    OcPrimaryCta(
                      label: 'Launch Mission',
                      icon: Icons.rocket_launch_rounded,
                      onPressed: ready
                          ? () {
                              OcHaptics.choice();
                              ref
                                  .read(missionSessionProvider.notifier)
                                  .beginRun();
                              context.push('/world');
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ready ? OcTokens.good : OcTokens.warn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ready
                              ? 'Outpost ready | All systems nominal'
                              : 'Over budget | Trim mass or power draw',
                          style: TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            color: ready
                                ? OcTokens.good
                                : OcTokens.warn,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
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

  static bool _isLocked(String id, int level) {
    return switch (id) {
      'lab' || 'spares' => level < 5,
      _ => false,
    };
  }
}

class _BuildHeader extends StatelessWidget {
  const _BuildHeader({
    required this.cadetLevel,
    required this.onBack,
  });

  final int cadetLevel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final dots = cadetLevel.clamp(1, 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          OcBackButton(onPressed: onBack),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OcAssetIcon(OcAssets.shieldStar, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'OUTPOST CADET',
                      style: TextStyle(
                        fontFamily: OcTokens.displayFamily,
                        color: OcTokens.bone,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '-- BUILD --',
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.rust,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ClipOval(
                child: Image.asset(
                  OcAssets.avatarBuildCadet,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CADET LVL $cadetLevel',
                style: const TextStyle(
                  fontFamily: OcTokens.bodyFamily,
                  color: OcTokens.sand,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (i) {
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < dots
                          ? OcTokens.rust
                          : OcTokens.sand.withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.barColor,
    required this.over,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color barColor;
  final bool over;

  @override
  Widget build(BuildContext context) {
    return OcPanel(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: OcTokens.bone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.sand,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: over ? OcTokens.danger : OcTokens.bone,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: OcTokens.spaceBlack,
              color: over ? OcTokens.danger : barColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.label,
    required this.moduleId,
    required this.isHabitat,
    required this.onTap,
  });

  final String label;
  final String? moduleId;
  final bool isHabitat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = moduleId != null;
    final borderColor = isHabitat
        ? OcTokens.rust
        : OcTokens.sand.withValues(alpha: 0.35);
    final shortName = filled
        ? (isHabitat
            ? 'HABITAT (FIXED)'
            : moduleId!.toUpperCase())
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: isHabitat ? 2.4 : 1,
            ),
            boxShadow: isHabitat
                ? [
                    BoxShadow(
                      color: OcTokens.rust.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                filled ? OcAssets.tile(moduleId!) : OcAssets.tileEmpty,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
              Positioned(
                top: 4,
                left: 5,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.bone.withValues(alpha: 0.85),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black87),
                    ],
                  ),
                ),
              ),
              if (shortName != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  child: Text(
                    shortName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: OcTokens.bodyFamily,
                      color: OcTokens.bone,
                      fontSize: isHabitat ? 8 : 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutBonusBanner extends StatelessWidget {
  const _LayoutBonusBanner({
    required this.notes,
    required this.active,
  });

  final List<String> notes;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final title = active
        ? 'LAYOUT BONUS: ${_bonusTitle(notes.first)}'
        : 'LAYOUT BONUS';
    final body = active
        ? notes.first
        : 'Place Shield beside Habitat or Greenhouse beside Recycler.';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: OcTokens.good.withValues(alpha: active ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(OcTokens.radiusSm),
        border: Border.all(
          color: OcTokens.good.withValues(alpha: active ? 0.55 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_rounded,
            color: OcTokens.good.withValues(alpha: active ? 1 : 0.5),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.good.withValues(alpha: active ? 1 : 0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.bone.withValues(alpha: 0.8),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            active
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: OcTokens.good.withValues(alpha: active ? 1 : 0.35),
            size: 26,
          ),
        ],
      ),
    );
  }

  static String _bonusTitle(String note) {
    final lower = note.toLowerCase();
    if (lower.contains('shield')) return 'SHIELD';
    if (lower.contains('greenhouse')) return 'GREENHOUSE';
    if (lower.contains('solar')) return 'SOLAR';
    return 'ACTIVE';
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.module,
    required this.selected,
    required this.placed,
    required this.locked,
    required this.canAdd,
    required this.onTap,
  });

  final OutpostModule module;
  final bool selected;
  final bool placed;
  final bool locked;
  final bool canAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = locked
        ? OcTokens.sand.withValues(alpha: 0.2)
        : selected
            ? OcTokens.shield
            : placed
                ? OcTokens.good.withValues(alpha: 0.7)
                : OcTokens.panelBorder;

    return Opacity(
      opacity: locked ? 0.45 : (canAdd || selected ? 1 : 0.7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 88,
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            decoration: BoxDecoration(
              color: OcTokens.panelSolid.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: OcTokens.shield.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        OcAssets.palette(module.id),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.name.split(' ').first.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: OcTokens.bodyFamily,
                        color: OcTokens.bone,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '${module.mass} kg',
                      style: const TextStyle(
                        fontFamily: OcTokens.bodyFamily,
                        color: OcTokens.sand,
                        fontSize: 9,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 10,
                          color: OcTokens.power,
                        ),
                        Text(
                          '${module.powerDraw} W',
                          style: const TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            color: OcTokens.sand,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (placed && !selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: OcTokens.good,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedPaletteCard extends StatelessWidget {
  const _LockedPaletteCard({required this.cadetLevel});

  final int cadetLevel;

  @override
  Widget build(BuildContext context) {
    final unlockAt = 5;
    final t = (cadetLevel / unlockAt).clamp(0.0, 1.0);
    return Container(
      width: 88,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: OcTokens.panelSolid.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OcTokens.sand.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Expanded(
            child: Center(
              child: Icon(
                Icons.lock_rounded,
                size: 36,
                color: OcTokens.sand,
              ),
            ),
          ),
          const Text(
            'LOCKED',
            style: TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.sand,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            'Unlock at Cadet LVL $unlockAt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.sand.withValues(alpha: 0.7),
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: t,
              minHeight: 4,
              backgroundColor: OcTokens.spaceBlack,
              color: OcTokens.rust,
            ),
          ),
        ],
      ),
    );
  }
}
