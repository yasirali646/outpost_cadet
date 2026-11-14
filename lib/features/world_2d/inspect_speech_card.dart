import 'package:flutter/material.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/services/oc_audio.dart';

/// Cadet inspect lines — character "speaks" about the nearby module.
String cadetInspectLine(String moduleId) {
  final base = moduleId.split('_').first;
  return switch (base) {
    'greenhouse' =>
        'Greenhouse looks healthy. If power dips, these plants go first — watch the meters.',
    'solar' =>
        'Solar rack is humming. Dust on the panels… I should keep storms in mind.',
    'battery' =>
        'Battery bank is stable. Good buffer if a flare knocks the arrays offline.',
    'recycler' =>
        'Water recycler’s cycling clean. Without this, life support burns through fast.',
    'shield' =>
        'Radiation shield’s up. Standing near it feels safer already.',
    'lab' =>
        'Lab systems nominal. Science can wait — surviving the sol comes first.',
    'spares' || 'storage' =>
        'Spares cache is stocked. Extra mass, but it’ll save us mid-mission.',
    'habitat' =>
        'Home base. When you’re ready, advance the sol from here.',
    _ =>
        'Systems nominal. Walk to the HABITAT when you want to advance a sol.',
  };
}

class InspectSpeechData {
  const InspectSpeechData({
    required this.title,
    required this.line,
    this.speaker = 'CADET',
    this.avatarAsset = OcAssets.avatarCadet,
  });

  final String title;
  final String line;
  final String speaker;
  final String avatarAsset;
}

/// Game-style speech card: avatar top-left + typewriter dialogue.
class InspectSpeechCard extends StatefulWidget {
  const InspectSpeechCard({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  final InspectSpeechData data;
  final VoidCallback onDismiss;

  @override
  State<InspectSpeechCard> createState() => _InspectSpeechCardState();
}

class _InspectSpeechCardState extends State<InspectSpeechCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  var _visibleChars = 0;
  var _typing = true;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _runTypewriter();
  }

  Future<void> _runTypewriter() async {
    final full = widget.data.line;
    for (var i = 1; i <= full.length; i++) {
      if (!mounted || !_typing) break;
      setState(() => _visibleChars = i);
      if (i % 3 == 0) {
        try {
          OcAudio.instance.tap();
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 28));
    }
    if (mounted) setState(() => _typing = false);
  }

  void _onTap() {
    OcHaptics.tap();
    if (_typing) {
      setState(() {
        _typing = false;
        _visibleChars = widget.data.line.length;
      });
      return;
    }
    widget.onDismiss();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.data.line.substring(
      0,
      _visibleChars.clamp(0, widget.data.line.length),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onTap,
              borderRadius: BorderRadius.circular(OcTokens.radiusMd),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                    decoration: BoxDecoration(
                      color: OcTokens.cream.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(OcTokens.radiusMd),
                      border: Border.all(
                        color: OcTokens.rust.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.data.speaker,
                              style: const TextStyle(
                                fontFamily: OcTokens.displayFamily,
                                color: OcTokens.rust,
                                fontSize: 22,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '· ${widget.data.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: OcTokens.bodyFamily,
                                  color: OcTokens.panelSolid.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: shown,
                                style: TextStyle(
                                  fontFamily: OcTokens.bodyFamily,
                                  color: OcTokens.panelSolid.withValues(
                                    alpha: 0.92,
                                  ),
                                  height: 1.35,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_typing)
                                TextSpan(
                                  text: '▌',
                                  style: TextStyle(
                                    color: OcTokens.rust.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _typing ? 'TAP TO SKIP' : 'TAP TO CLOSE',
                            style: TextStyle(
                              fontFamily: OcTokens.bodyFamily,
                              color: OcTokens.rust.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 0,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: OcTokens.panelSolid,
                        border: Border.all(color: OcTokens.rust, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        widget.data.avatarAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
