import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/models/models.dart';
import 'package:outpost_cadet/services/mission_session.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  var _dialogOpen = false;

  Future<void> _closeDialogIfOpen() async {
    if (!_dialogOpen) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
    _dialogOpen = false;
  }

  Future<void> _openEventPopup(
    MissionEventDef event, {
    required bool choiceMode,
  }) async {
    if (!mounted || _dialogOpen) return;
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: !choiceMode,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (ctx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              child: _EventPanel(
                event: event,
                choiceMode: choiceMode,
                showChoicePreview: !choiceMode && event.choices.isNotEmpty,
                onChoose: (id) {
                  OcHaptics.choice();
                  ref.read(missionSessionProvider.notifier).resolveChoice(id);
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }
                },
                onDismiss: () {
                  if (choiceMode) return;
                  ref.read(missionSessionProvider.notifier).clearLastEvent();
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ),
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _openHelpPopup() async {
    final state = ref.read(missionSessionProvider);
    final catalog = ref.read(contentCatalogProvider).valueOrNull;

    MissionEventDef? event = state?.awaitingChoice == true
        ? state?.pendingEvent
        : state?.lastEvent ?? state?.activeEvent?.def;

    if (event == null && catalog != null) {
      for (final e in catalog.events) {
        if (e.id == 'solar_flare') {
          event = e;
          break;
        }
      }
    }

    event ??= MissionEventDef(
      id: 'solar_flare',
      name: 'Solar Flare',
      description:
          'A solar flare has been detected. Increased radiation outside. How will the crew respond?',
      durationSols: 2,
      multipliers: EventMultipliers.identity,
      tone: 'danger',
      factId: 'fact_flare',
      choices: const [],
    );

    final choiceMode =
        state?.awaitingChoice == true && state?.pendingEvent != null;

    await _openEventPopup(
      event,
      choiceMode: choiceMode,
    );
  }

  Future<void> _goBack() async {
    await _closeDialogIfOpen();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/missions');
    }
  }

  Future<void> _openMissionLog() async {
    await _closeDialogIfOpen();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mission log: advance sols and respond to events. Facts unlock at debrief.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionSessionProvider);

    ref.listen<MissionState?>(missionSessionProvider, (prev, next) {
      if (next == null) return;
      if (next.phase == MissionPhase.won || next.phase == MissionPhase.lost) {
        if (next.phase == MissionPhase.lost) {
          OcHaptics.fail();
        }
        final router = GoRouter.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _closeDialogIfOpen();
          if (!mounted) return;
          router.go('/debrief');
        });
        return;
      }
      if (next.awaitingChoice &&
          next.pendingEvent != null &&
          !(prev?.awaitingChoice ?? false)) {
        OcHaptics.warn();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openEventPopup(next.pendingEvent!, choiceMode: true);
        });
      } else if (next.lastEvent != null &&
          !next.awaitingChoice &&
          !next.lastEvent!.hasChoices &&
          (prev?.lastEvent?.id != next.lastEvent?.id ||
              prev?.sol != next.sol)) {
        OcHaptics.soft();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openEventPopup(next.lastEvent!, choiceMode: false);
        });
      }
    });

    if (state == null || state.phase == MissionPhase.building) {
      return Scaffold(
        backgroundColor: OcTokens.spaceBlack,
        body: MarsBackdrop(
          imageAsset: OcAssets.marsBgRun,
          child: Center(
            child: FilledButton(
              onPressed: () => context.go('/missions'),
              child: const Text('Start from brief'),
            ),
          ),
        ),
      );
    }

    final pending = state.awaitingChoice ? state.pendingEvent : null;
    final helpName = pending?.name ??
        state.activeEvent?.def.name ??
        state.lastEvent?.name;
    final canAdvance =
        state.phase == MissionPhase.running && !state.awaitingChoice;
    final atmosphereEvent = pending ?? state.activeEvent?.def;

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: MarsBackdrop(
        imageAsset: OcAssets.marsBgRun,
        dim: 0.38,
        child: OcEventAtmosphere(
          eventId: atmosphereEvent?.id,
          tone: atmosphereEvent?.tone,
          child: SafeArea(
            child: Column(
              children: [
                _RunHeader(
                  sol: state.sol,
                  maxSols: state.mission.sols,
                  onMenu: _goBack,
                  onMissionLog: _openMissionLog,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ResourceStrip(meters: state.meters),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• BASE PREVIEW •',
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.sand,
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _BasePreviewGrid(
                      placements: state.placements,
                      pulseHabitat: atmosphereEvent != null,
                    ),
                  ),
                ),
                if (state.activeEvent != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: OcPulseGlow(
                      child: _ActiveEventChip(
                        event: state.activeEvent!,
                        onOpen: () => _openEventPopup(
                          state.activeEvent!.def,
                          choiceMode: false,
                        ),
                      ),
                    ),
                  ),
                if (state.warning != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Text(
                      state.warning!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: OcTokens.warn,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (state.awaitingChoice)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final e = state.pendingEvent;
                          if (e != null) {
                            OcHaptics.warn();
                            _openEventPopup(e, choiceMode: true);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OcTokens.rust,
                          side: const BorderSide(
                              color: OcTokens.rust, width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: Text(
                          'OPEN ${(state.pendingEvent?.name ?? 'EVENT').toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (canAdvance)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          OcHaptics.soft();
                          ref
                              .read(missionSessionProvider.notifier)
                              .advanceSol();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: OcTokens.rust,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(OcTokens.radiusSm),
                          ),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 26),
                        label: const Text(
                          'ADVANCE SOL',
                          style: TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                _RunFooter(
                  eventName: helpName,
                  onHelp: () {
                    OcHaptics.warn();
                    _openHelpPopup();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunHeader extends StatelessWidget {
  const _RunHeader({
    required this.sol,
    required this.maxSols,
    required this.onMenu,
    required this.onMissionLog,
  });

  final int sol;
  final int maxSols;
  final VoidCallback onMenu;
  final VoidCallback onMissionLog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 10, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OcBackButton(onPressed: onMenu),
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
                  'RUN MISSION',
                  style: TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.rust,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: OcTokens.panelSolid.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OcTokens.panelBorder),
                ),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: OcTokens.bodyFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      const TextSpan(
                        text: 'SOL ',
                        style: TextStyle(color: OcTokens.rust),
                      ),
                      TextSpan(
                        text: '$sol',
                        style: const TextStyle(color: OcTokens.rust),
                      ),
                      TextSpan(
                        text: ' / $maxSols',
                        style: const TextStyle(color: OcTokens.bone),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: onMissionLog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: OcTokens.panelSolid.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OcTokens.panelBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: OcTokens.bone),
                      SizedBox(width: 3),
                      Text(
                        'MISSION LOG',
                        style: TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: OcTokens.bone,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceStrip extends StatelessWidget {
  const _ResourceStrip({required this.meters});

  final ResourceMeters meters;

  @override
  Widget build(BuildContext context) {
    final shieldLeft = meters.radiationCap - meters.radiation;
    return Row(
      children: [
        Expanded(
          child: _MeterCard(
            icon: Icons.favorite_rounded,
            label: 'LIFE',
            value: meters.lifeSupport,
            max: meters.lifeCap,
            color: OcTokens.life,
            warn: meters.lifeCritical,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MeterCard(
            icon: Icons.shield_rounded,
            label: 'SHIELD',
            value: shieldLeft,
            max: meters.radiationCap,
            color: OcTokens.shield,
            warn: meters.radiationCritical,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MeterCard(
            icon: Icons.bolt_rounded,
            label: 'POWER',
            value: meters.power,
            max: meters.powerCap,
            color: OcTokens.power,
            warn: meters.powerCritical,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MeterCard(
            icon: Icons.eco_rounded,
            label: 'FOOD',
            value: meters.food,
            max: meters.foodCap,
            color: OcTokens.food,
            warn: meters.foodCritical,
          ),
        ),
      ],
    );
  }
}

class _MeterCard extends StatelessWidget {
  const _MeterCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.warn,
  });

  final IconData icon;
  final String label;
  final double value;
  final double max;
  final Color color;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final t = (value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: OcTokens.panelSolid.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OcTokens.panelBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: warn ? OcTokens.danger : OcTokens.sand,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          OcAnimatedMeter(
            value: t,
            color: warn ? OcTokens.danger : color,
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            '${value.round()} / ${max.round()}',
            style: const TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.bone,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasePreviewGrid extends StatelessWidget {
  const _BasePreviewGrid({
    required this.placements,
    this.pulseHabitat = false,
  });

  final List<String?> placements;
  final bool pulseHabitat;

  static const _cells = <({String id, String label, IconData icon})>[
    (id: 'habitat', label: 'HABITAT', icon: Icons.home_rounded),
    (id: 'greenhouse', label: 'GREENHOUSE', icon: Icons.eco_rounded),
    (id: 'workshop', label: 'WORKSHOP', icon: Icons.settings_rounded),
    (id: 'power_plant', label: 'POWER PLANT', icon: Icons.bolt_rounded),
    (id: 'airlock', label: 'AIRLOCK', icon: Icons.door_front_door_outlined),
    (id: 'storage', label: 'STORAGE', icon: Icons.inventory_2_outlined),
    (id: 'water_recycler', label: 'WATER RECYCLER', icon: Icons.water_drop),
    (id: 'med_bay', label: 'MED BAY', icon: Icons.add_box_outlined),
    (id: 'command', label: 'COMMAND', icon: Icons.flag_rounded),
  ];

  static String? _facilityForModule(String? moduleId) {
    return switch (moduleId) {
      'habitat' => 'habitat',
      'greenhouse' => 'greenhouse',
      'recycler' => 'water_recycler',
      'solar' || 'battery' => 'power_plant',
      'shield' => 'airlock',
      'lab' => 'med_bay',
      'spares' => 'storage',
      _ => null,
    };
  }

  Set<String> get _owned {
    final out = <String>{};
    for (final id in placements) {
      final f = _facilityForModule(id);
      if (f != null) out.add(f);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final owned = _owned;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cells.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final cell = _cells[i];
        final active = owned.contains(cell.id);
        final tile = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? OcTokens.rust.withValues(alpha: 0.75)
                  : OcTokens.sand.withValues(alpha: 0.28),
              width: active ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: active ? 1 : 0.65,
                child: Image.asset(
                  OcAssets.facility(cell.id),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Row(
                    children: [
                      Icon(cell.icon, size: 10, color: OcTokens.bone),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          cell.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            color: OcTokens.bone,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        if (cell.id == 'habitat' && active && pulseHabitat) {
          return OcPulseGlow(child: tile);
        }
        return tile;
      },
    );
  }
}

class _ActiveEventChip extends StatelessWidget {
  const _ActiveEventChip({
    required this.event,
    required this.onOpen,
  });

  final ActiveEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(OcTokens.radiusMd),
        child: OcPanel(
          highlighted: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: OcTokens.rust, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${event.def.name.toUpperCase()} · ${event.solsRemaining} sol(s) left',
                  style: const TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.bone,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new_rounded,
                  color: OcTokens.sand, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventPanel extends StatelessWidget {
  const _EventPanel({
    required this.event,
    required this.choiceMode,
    required this.onChoose,
    required this.onDismiss,
    this.showChoicePreview = false,
  });

  final MissionEventDef event;
  final bool choiceMode;
  final bool showChoicePreview;
  final ValueChanged<String> onChoose;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final showChoices = choiceMode || showChoicePreview;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: OcTokens.panelSolid.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OcTokens.rust.withValues(alpha: 0.75),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: OcTokens.rust, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: OcTokens.bodyFamily,
                    color: OcTokens.rust,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: choiceMode ? null : onDismiss,
                icon: Icon(
                  Icons.close,
                  color: OcTokens.sand.withValues(alpha: choiceMode ? 0.35 : 1),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.description,
            style: const TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.bone,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (showChoices) ...[
            const SizedBox(height: 6),
            Text(
              choiceMode
                  ? 'Risk vs. safety. Choose wisely.'
                  : 'Example responses (open during a live flare to choose):',
              style: TextStyle(
                fontFamily: OcTokens.bodyFamily,
                color: OcTokens.sand.withValues(alpha: 0.95),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ...event.choices.map((c) {
              final good = c.recommended;
              final button = _ChoiceButton(
                choice: c,
                accent: good ? OcTokens.good : OcTokens.rust,
                leading:
                    good ? Icons.shield_rounded : Icons.warning_amber_rounded,
                onTap: choiceMode ? () => onChoose(c.id) : onDismiss,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: choiceMode
                    ? button
                    : Opacity(opacity: 0.92, child: button),
              );
            }),
            const SizedBox(height: 2),
            Text(
              '• ${_footerTip(event)} •',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: OcTokens.bodyFamily,
                color: OcTokens.sand.withValues(alpha: 0.8),
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ],
          if (!choiceMode) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onDismiss,
              style: FilledButton.styleFrom(
                backgroundColor: OcTokens.rust,
                foregroundColor: Colors.white,
              ),
              child: const Text('GOT IT'),
            ),
          ],
        ],
      ),
    );
  }

  static String _footerTip(MissionEventDef event) {
    final id = event.id.toLowerCase();
    if (id.contains('flare')) {
      return 'Solar flares can strip away atmosphere protection and damage cells. Shielding saves lives.';
    }
    if (id.contains('dust')) {
      return 'Dust storms choke solar panels. Batteries keep life support online.';
    }
    if (id.contains('glitch')) {
      return 'Life-support glitches need fast repairs — power spent now saves crew later.';
    }
    return 'Every choice shapes your debrief score. Think like an engineer.';
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.accent,
    required this.leading,
    required this.onTap,
  });

  final EventChoice choice;
  final Color accent;
  final IconData leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cost = _costChip(choice.instant, accent);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(leading, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.label.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: OcTokens.bone,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        choice.blurb,
                        style: TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: OcTokens.sand.withValues(alpha: 0.95),
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cost != null) ...[
                  const SizedBox(width: 8),
                  cost,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget? _costChip(InstantDelta d, Color fallback) {
    if (d.power != 0) {
      return _delta(Icons.bolt_rounded, OcTokens.power, d.power);
    }
    if (d.lifeSupport != 0) {
      return _delta(Icons.favorite_rounded, OcTokens.life, d.lifeSupport);
    }
    if (d.food != 0) {
      return _delta(Icons.eco_rounded, OcTokens.food, d.food);
    }
    if (d.radiation != 0) {
      return _delta(Icons.shield_rounded, OcTokens.shield, d.radiation);
    }
    return null;
  }

  static Widget _delta(IconData icon, Color color, double value) {
    final sign = value > 0 ? '+' : '';
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        Text(
          '$sign${value.round()}',
          style: TextStyle(
            fontFamily: OcTokens.bodyFamily,
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RunFooter extends StatelessWidget {
  const _RunFooter({
    required this.eventName,
    required this.onHelp,
  });

  final String? eventName;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final helpLabel = eventName == null
        ? 'FLARE HELP'
        : '${eventName!.split(' ').first.toUpperCase()} HELP';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OcTokens.panelSolid.withValues(alpha: 0.9),
              border: Border.all(color: OcTokens.panelBorder, width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.explore_rounded,
                    color: OcTokens.bone, size: 30),
                Positioned(
                  bottom: 6,
                  child: Text(
                    'NE 128°',
                    style: TextStyle(
                      fontFamily: OcTokens.bodyFamily,
                      color: OcTokens.sand.withValues(alpha: 0.95),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onHelp,
            style: TextButton.styleFrom(
              foregroundColor: OcTokens.bone,
              backgroundColor: OcTokens.panelSolid.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: OcTokens.panelBorder),
              ),
            ),
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: Text(
              helpLabel,
              style: const TextStyle(
                fontFamily: OcTokens.bodyFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
