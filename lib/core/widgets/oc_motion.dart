import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/services/oc_audio.dart';

/// Light haptic + sound helpers for cadet actions.
abstract final class OcHaptics {
  static void tap() {
    HapticFeedback.selectionClick();
    OcAudio.instance.tap();
  }

  static void soft() {
    HapticFeedback.lightImpact();
    OcAudio.instance.sol();
  }

  static void warn() {
    HapticFeedback.mediumImpact();
    OcAudio.instance.warn();
  }

  static void success() {
    HapticFeedback.heavyImpact();
    OcAudio.instance.success();
  }

  static void fail() {
    HapticFeedback.heavyImpact();
    OcAudio.instance.fail();
  }

  static void choice() {
    HapticFeedback.selectionClick();
    OcAudio.instance.choice();
  }

  static void place() {
    HapticFeedback.mediumImpact();
    OcAudio.instance.place();
  }

  static void remove() {
    HapticFeedback.lightImpact();
    OcAudio.instance.remove();
  }

  /// Empty tile / no palette pick / can't place.
  static void empty() {
    HapticFeedback.selectionClick();
    OcAudio.instance.empty();
  }
}

/// Scale-in entrance (trophy, emblem, etc.).
class OcScaleIn extends StatefulWidget {
  const OcScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
    this.begin = 0.55,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double begin;

  @override
  State<OcScaleIn> createState() => _OcScaleInState();
}

class _OcScaleInState extends State<OcScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.45, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: widget.begin, end: 1).animate(_scale),
        child: widget.child,
      ),
    );
  }
}

/// Soft orange pulse around a child (habitat / event accent).
class OcPulseGlow extends StatefulWidget {
  const OcPulseGlow({
    super.key,
    required this.child,
    this.color = OcTokens.rust,
    this.enabled = true,
  });

  final Widget child;
  final Color color;
  final bool enabled;

  @override
  State<OcPulseGlow> createState() => _OcPulseGlowState();
}

class _OcPulseGlowState extends State<OcPulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant OcPulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.enabled && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + t * 0.35),
                blurRadius: 6 + t * 10,
                spreadRadius: t * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Animated meter fill when value changes.
class OcAnimatedMeter extends StatelessWidget {
  const OcAnimatedMeter({
    super.key,
    required this.value,
    required this.color,
    this.minHeight = 5,
    this.duration = const Duration(milliseconds: 450),
  });

  final double value;
  final Color color;
  final double minHeight;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v,
            minHeight: minHeight,
            backgroundColor: OcTokens.spaceBlack,
            color: color,
          ),
        );
      },
    );
  }
}

/// Soft screen tint for live events (flare / dust).
class OcEventAtmosphere extends StatelessWidget {
  const OcEventAtmosphere({
    super.key,
    required this.child,
    this.eventId,
    this.tone,
  });

  final Widget child;
  final String? eventId;
  final String? tone;

  Color? get _tint {
    final id = eventId?.toLowerCase() ?? '';
    if (id.contains('flare')) {
      return const Color(0xFFFF6A1A).withValues(alpha: 0.18);
    }
    if (id.contains('dust')) {
      return const Color(0xFFC47A3A).withValues(alpha: 0.22);
    }
    if (tone == 'danger') {
      return OcTokens.danger.withValues(alpha: 0.12);
    }
    if (tone == 'warn') {
      return OcTokens.warn.withValues(alpha: 0.12);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tint;
    if (tint == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: tint,
          ),
        ),
      ],
    );
  }
}
