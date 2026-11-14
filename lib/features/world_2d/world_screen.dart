import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/features/world_2d/event_cinematic_dialog.dart';
import 'package:outpost_cadet/features/world_2d/inspect_speech_card.dart';
import 'package:outpost_cadet/features/world_2d/outpost_game.dart';
import 'package:outpost_cadet/models/models.dart';
import 'package:outpost_cadet/services/mission_session.dart';

class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key});

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> {
  OutpostGame? _game;
  final _nearest = ValueNotifier<WorldBuilding?>(null);
  final _speech = ValueNotifier<InspectSpeechData?>(null);
  var _dialogOpen = false;
  List<String?>? _placementsKey;
  final _stickKey = GlobalKey();

  @override
  void dispose() {
    _nearest.dispose();
    _speech.dispose();
    super.dispose();
  }

  void _ensureGame(List<String?> placements) {
    final key = List<String?>.from(placements);
    if (_game != null && _listEq(_placementsKey, key)) return;
    _placementsKey = key;
    _game = OutpostGame(
      placements: key,
      onNearestChanged: (b) {
        // ValueNotifier — do NOT setState (that cancels joystick pan mid-walk).
        if (_nearest.value?.moduleId == b?.moduleId &&
            identical(_nearest.value, b)) {
          return;
        }
        if (_nearest.value?.moduleId == b?.moduleId) return;
        _nearest.value = b;
      },
    );
  }

  bool _listEq(List<String?>? a, List<String?> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _closeDialogIfOpen() async {
    if (!_dialogOpen) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
    _dialogOpen = false;
  }

  Future<void> _openEventPopup(
    MissionEventDef event, {
    required bool choiceMode,
  }) async {
    if (!mounted || _dialogOpen) return;
    _dialogOpen = true;
    _speech.value = null;
    try {
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: !choiceMode,
        barrierLabel: 'event',
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        pageBuilder: (ctx, anim, secondaryAnim) {
          final mission = ref.read(missionSessionProvider)?.mission;
          return EventCinematicDialog(
            event: event,
            choiceMode: choiceMode,
            commsDelay:
                mission?.commsDelay ?? const Duration(minutes: 20),
            bodyLabel: mission?.bodyLabel ?? 'Mars',
            onChoice: (id) {
              ref.read(missionSessionProvider.notifier).resolveChoice(id);
              Navigator.of(ctx).pop();
            },
            onContinue: () {
              ref.read(missionSessionProvider.notifier).clearLastEvent();
              Navigator.of(ctx).pop();
            },
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  void _interact(MissionState state) {
    final near = _nearest.value;
    if (near == null) {
      OcHaptics.empty();
      return;
    }
    if (state.awaitingChoice && state.pendingEvent != null) {
      OcHaptics.warn();
      _openEventPopup(state.pendingEvent!, choiceMode: true);
      return;
    }
    if (near.isHabitat) {
      if (state.phase != MissionPhase.running || state.awaitingChoice) {
        OcHaptics.empty();
        return;
      }
      OcHaptics.soft();
      ref.read(missionSessionProvider.notifier).advanceSol();
      return;
    }
    OcHaptics.tap();
    _speech.value = InspectSpeechData(
      title: near.label,
      line: cadetInspectLine(near.moduleId),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionSessionProvider);

    ref.listen<MissionState?>(missionSessionProvider, (prev, next) {
      if (next == null) return;
      if (next.phase == MissionPhase.won || next.phase == MissionPhase.lost) {
        if (next.phase == MissionPhase.lost) OcHaptics.fail();
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

    _ensureGame(state.placements);
    final game = _game!;

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          // Top HUD only — does not cover the playfield.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OcPageHeader(
                    subtitle: 'WALK MISSION',
                    leading: OcBackButton(onPressed: _goBack),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: OcTokens.panelSolid.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OcTokens.panelBorder),
                      ),
                      child: Text(
                        'SOL ${state.sol} / ${state.mission.sols}',
                        style: const TextStyle(
                          color: OcTokens.rust,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: OcPanel(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: _MiniMeters(meters: state.meters),
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
                ],
              ),
            ),
          ),
          // Joystick isolated from nearest HUD rebuilds (keeps pan alive).
          Positioned(
            left: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: _VirtualStick(
                key: _stickKey,
                onChanged: (dx, dy) {
                  _game?.externalInput.setValues(dx, dy);
                },
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: ValueListenableBuilder<InspectSpeechData?>(
                valueListenable: _speech,
                builder: (context, speech, _) {
                  if (speech != null) return const SizedBox.shrink();
                  return ValueListenableBuilder<WorldBuilding?>(
                    valueListenable: _nearest,
                    builder: (context, near, _) {
                      final canInteract = near != null || state.awaitingChoice;
                      final interactLabel = state.awaitingChoice
                          ? 'OPEN EVENT'
                          : (near?.isHabitat ?? false)
                              ? 'ADVANCE SOL'
                              : near != null
                                  ? 'INSPECT'
                                  : 'WALK CLOSER';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (near != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, right: 4),
                              child: Text(
                                'NEAR: ${near.label}',
                                style: const TextStyle(
                                  color: OcTokens.sand,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  fontSize: 11,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 160,
                            child: FilledButton(
                              onPressed: canInteract
                                  ? () => _interact(state)
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: OcTokens.rust,
                                disabledBackgroundColor: OcTokens.panelSolid
                                    .withValues(alpha: 0.7),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                interactLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Cadet speech / inspect card (avatar + typewriter).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<InspectSpeechData?>(
              valueListenable: _speech,
              builder: (context, data, _) {
                if (data == null) return const SizedBox.shrink();
                return InspectSpeechCard(
                  key: ValueKey('${data.title}_${data.line}'),
                  data: data,
                  onDismiss: () => _speech.value = null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtualStick extends StatefulWidget {
  const _VirtualStick({super.key, required this.onChanged});

  final void Function(double dx, double dy) onChanged;

  @override
  State<_VirtualStick> createState() => _VirtualStickState();
}

class _VirtualStickState extends State<_VirtualStick> {
  Offset _knob = Offset.zero;
  static const radius = 56.0;

  void _update(Offset local) {
    final delta = local - const Offset(radius, radius);
    final clamped = Offset.fromDirection(
      delta.direction,
      delta.distance.clamp(0, radius),
    );
    setState(() => _knob = clamped);
    widget.onChanged(clamped.dx / radius, clamped.dy / radius);
  }

  void _reset() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _update(e.localPosition),
        onPointerMove: (e) => _update(e.localPosition),
        onPointerUp: (_) => _reset(),
        onPointerCancel: (_) => _reset(),
        child: CustomPaint(
          painter: _StickPainter(knob: _knob, radius: radius),
        ),
      ),
    );
  }
}

class _StickPainter extends CustomPainter {
  _StickPainter({required this.knob, required this.radius});

  final Offset knob;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(radius, radius);
    canvas.drawCircle(
      c,
      radius,
      Paint()..color = const Color(0xAA1A1423),
    );
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = OcTokens.rust.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c + knob,
      22,
      Paint()..color = const Color(0xFFE8C56A),
    );
  }

  @override
  bool shouldRepaint(covariant _StickPainter oldDelegate) =>
      oldDelegate.knob != knob;
}

class _MiniMeters extends StatelessWidget {
  const _MiniMeters({required this.meters});

  final ResourceMeters meters;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, double v, double max, Color c) {
      final t = (v / max).clamp(0.0, 1.0);
      return Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: OcTokens.sand.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            OcAnimatedMeter(value: t, color: c, minHeight: 5),
          ],
        ),
      );
    }

    return Row(
      children: [
        chip('LIFE', meters.lifeSupport, meters.lifeCap, OcTokens.life),
        const SizedBox(width: 8),
        chip(
          'SHIELD',
          meters.radiationCap - meters.radiation,
          meters.radiationCap,
          OcTokens.shield,
        ),
        const SizedBox(width: 8),
        chip('POWER', meters.power, meters.powerCap, OcTokens.power),
        const SizedBox(width: 8),
        chip('FOOD', meters.food, meters.foodCap, OcTokens.food),
      ],
    );
  }
}
