import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/mars_colors.dart';
import 'package:outpost_cadet/core/widgets/mars_widgets.dart';
import 'package:outpost_cadet/services/progress_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: 'You are Mission Control',
      body:
          'Build a Moon or Mars outpost. Every module costs mass and power. Nothing is free!',
      icon: Icons.rocket_launch_rounded,
    ),
    (
      title: 'Four meters to watch',
      body:
          'LIFE (air/water), SHIELD (radiation), POWER, and FOOD. If any hit zero — or radiation fills up — the mission fails.',
      icon: Icons.tune_rounded,
    ),
    (
      title: 'Real trade-offs',
      body:
          'Save power today, maybe lose food tomorrow. Earth radio is slow on Mars (~20 min). NASA space weather can change how risky flares are.',
      icon: Icons.lightbulb_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarsScaffold(
      title: 'Cadet Briefing',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: FilledButton(
          onPressed: () async {
            if (_page < _pages.length - 1) {
              _controller.nextPage(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
            } else {
              await ref
                  .read(progressControllerProvider.notifier)
                  .completeOnboarding();
              if (context.mounted) context.go('/missions');
            }
          },
          child: Text(_page < _pages.length - 1 ? 'Next' : 'Choose Mission'),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(p.icon, size: 72, color: MarsColors.rust),
                      const SizedBox(height: 24),
                      Text(
                        p.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        p.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? MarsColors.rust
                      : MarsColors.sand.withValues(alpha: 0.35),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
