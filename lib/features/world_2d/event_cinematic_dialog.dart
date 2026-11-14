import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/models/models.dart';

/// Full-screen event: atmosphere FX first, then a TCG-style card slam.
class EventCinematicDialog extends StatefulWidget {
  const EventCinematicDialog({
    super.key,
    required this.event,
    required this.choiceMode,
    this.onChoice,
    this.onContinue,
    this.commsDelay = const Duration(minutes: 20),
    this.bodyLabel = 'Mars',
  });

  final MissionEventDef event;
  final bool choiceMode;
  final void Function(String choiceId)? onChoice;
  final VoidCallback? onContinue;

  /// One-way Earth radio delay for the teaching strip.
  final Duration commsDelay;
  final String bodyLabel;

  @override
  State<EventCinematicDialog> createState() => _EventCinematicDialogState();
}

class _EventCinematicDialogState extends State<EventCinematicDialog>
    with TickerProviderStateMixin {
  late final AnimationController _fx;
  late final AnimationController _card;
  var _showCard = false;

  bool get _isFlare {
    final id = widget.event.id.toLowerCase();
    final name = widget.event.name.toLowerCase();
    return id.contains('flare') || name.contains('flare');
  }

  bool get _isDust {
    final id = widget.event.id.toLowerCase();
    final name = widget.event.name.toLowerCase();
    return id.contains('dust') || name.contains('dust');
  }

  @override
  void initState() {
    super.initState();
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _card = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _playSequence();
  }

  Future<void> _playSequence() async {
    OcHaptics.warn();
    await _fx.forward();
    if (!mounted) return;
    setState(() => _showCard = true);
    OcHaptics.tap();
    await _card.forward();
  }

  @override
  void dispose() {
    _fx.dispose();
    _card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _fx,
            builder: (context, _) => _EventAtmosphereFx(
              progress: _fx.value,
              flare: _isFlare,
              dust: _isDust,
              banner: widget.event.name.toUpperCase(),
            ),
          ),
          if (_showCard)
            Center(
              child: AnimatedBuilder(
                animation: _card,
                builder: (context, child) {
                  final t = Curves.easeOutBack.transform(
                    _card.value.clamp(0.0, 1.0),
                  );
                  final scale = 1.55 - (0.55 * t);
                  final tilt = (1 - t) * 0.55;
                  final dy = (1 - t) * -48;
                      return Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..translateByDouble(0, dy, 0, 1)
                        ..rotateX(tilt * 0.35)
                        ..rotateZ((1 - t) * -0.08)
                        ..scaleByDouble(scale, scale, 1, 1),
                      child: child,
                    ),
                  );
                },
                child: _EventChoiceCard(
                  event: widget.event,
                  choiceMode: widget.choiceMode,
                  onChoice: widget.onChoice,
                  onContinue: widget.onContinue,
                  commsDelay: widget.commsDelay,
                  bodyLabel: widget.bodyLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventAtmosphereFx extends StatelessWidget {
  const _EventAtmosphereFx({
    required this.progress,
    required this.flare,
    required this.dust,
    required this.banner,
  });

  final double progress;
  final bool flare;
  final bool dust;
  final String banner;

  @override
  Widget build(BuildContext context) {
    // Pulse: bright flash early, then settle into wash.
    final flash = (math.sin(progress * math.pi * 2.2).abs() *
            (1 - progress) *
            0.55) +
        progress * 0.2;
    final wash = progress.clamp(0.0, 1.0);

    Color core;
    Color rim;
    if (flare) {
      core = const Color(0xFFFFF2C8);
      rim = const Color(0xFFFF6A1A);
    } else if (dust) {
      core = const Color(0xFFE8C090);
      rim = const Color(0xFFC47A3A);
    } else {
      core = OcTokens.warn;
      rim = OcTokens.rust;
    }

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dim world behind FX
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.35 + wash * 0.35),
          ),
          // Radial flare / radiation bloom
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: flare
                    ? const Alignment(0.15, -0.55)
                    : Alignment.center,
                radius: 1.15,
                colors: [
                  core.withValues(alpha: flash * 0.85),
                  rim.withValues(alpha: wash * 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
          // Edge vignette / radiation burn
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  rim.withValues(alpha: wash * 0.55),
                  Colors.transparent,
                  rim.withValues(alpha: wash * 0.35),
                ],
              ),
            ),
          ),
          if (flare)
            ...List.generate(8, (i) {
              final a = (i / 8) * math.pi * 2 + progress * 3;
              final r = 40.0 + i * 18 + flash * 30;
              return Align(
                alignment: Alignment(
                  math.cos(a) * 0.55,
                  math.sin(a) * 0.35 - 0.2,
                ),
                child: Opacity(
                  opacity: (1 - progress) * 0.7,
                  child: Container(
                    width: r * 0.08,
                    height: r * 0.08,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: core.withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: rim.withValues(alpha: 0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          if (dust)
            ...List.generate(5, (i) {
              final y = -0.8 + i * 0.35;
              return Align(
                alignment: Alignment(-1.2 + progress * 2.2, y),
                child: Opacity(
                  opacity: 0.25 + wash * 0.35,
                  child: Container(
                    width: 180,
                    height: 10 + i * 2.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: rim.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }),
          // Banner label during FX
          if (progress > 0.15 && progress < 0.95)
            Align(
              alignment: const Alignment(0, -0.72),
              child: Opacity(
                opacity: (math.sin(progress * math.pi)).clamp(0.0, 1.0),
                child: Text(
                  banner,
                  style: TextStyle(
                    fontFamily: OcTokens.displayFamily,
                    color: core,
                    fontSize: 34,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(color: rim, blurRadius: 18),
                      const Shadow(color: Colors.black, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventChoiceCard extends StatelessWidget {
  const _EventChoiceCard({
    required this.event,
    required this.choiceMode,
    this.onChoice,
    this.onContinue,
    this.commsDelay = const Duration(minutes: 20),
    this.bodyLabel = 'Mars',
  });

  final MissionEventDef event;
  final bool choiceMode;
  final void Function(String choiceId)? onChoice;
  final VoidCallback? onContinue;
  final Duration commsDelay;
  final String bodyLabel;

  String get _delayKid {
    if (commsDelay.inSeconds <= 2) {
      return 'Earth radio ~1 second away (almost instant).';
    }
    final m = commsDelay.inMinutes;
    return 'Earth radio ~$m minutes away — decide before advice arrives.';
  }

  @override
  Widget build(BuildContext context) {
    final recommended = event.choices.where((c) => c.recommended);
    final earthTip =
        recommended.isEmpty ? null : recommended.first.label;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Material(
        color: OcTokens.panelSolid,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(OcTokens.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OcTokens.radiusLg),
            border: Border.all(
              color: OcTokens.rust.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: OcTokens.displayFamily,
                  color: OcTokens.rust,
                  fontSize: 28,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OcTokens.bone,
                  height: 1.4,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (choiceMode) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: OcTokens.warn.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COMMS · $bodyLabel'.toUpperCase(),
                        style: const TextStyle(
                          color: OcTokens.warn,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _delayKid,
                        style: const TextStyle(
                          color: OcTokens.sand,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      if (earthTip != null &&
                          commsDelay.inSeconds > 2) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Earth’s advice is still in transit… (they often say “$earthTip”)',
                          style: TextStyle(
                            color: OcTokens.sand.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (choiceMode)
                ...event.choices.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledButton(
                      onPressed: () {
                        OcHaptics.choice();
                        onChoice?.call(c.id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: OcTokens.rust,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      child: Text(
                        c.label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () {
                    OcHaptics.tap();
                    onContinue?.call();
                  },
                  child: const Text('CONTINUE'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
