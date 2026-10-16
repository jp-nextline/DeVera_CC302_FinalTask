import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/fancy.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final palette = context.appPalette;
    final user = state.user;
    final name = user?.displayName ?? '';

    // Progress chart: learned cards in up to 6 biggest decks
    final decks = [...state.decks]
      ..sort((a, b) => b.cards.length.compareTo(a.cards.length));
    final top = decks.take(6).toList();

    return GradientScaffold(
      useGradient: false,
      title: const Text('User Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FadeSlideIn(
            index: 0,
            child: Column(
              children: [
                UserAvatar(name: name, radius: 46),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '@${user?.username ?? ''}',
                  style: TextStyle(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _StatBox(
                index: 1,
                icon: Icons.style_rounded,
                color: palette.blueLight,
                label: 'Decks',
                value: state.decks.length,
              ),
              const SizedBox(width: 12),
              _StatBox(
                index: 2,
                icon: Icons.layers_rounded,
                color: palette.cyan,
                label: 'Cards',
                value: state.totalCards,
              ),
              const SizedBox(width: 12),
              _StatBox(
                index: 3,
                icon: Icons.check_circle_rounded,
                color: palette.green,
                label: 'Learned',
                value: state.totalKnown,
              ),
            ],
          ),
          const SizedBox(height: 18),
          DepthCard(
            entranceIndex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Cards studied per day (last 14 days)',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SimpleLineChart(values: state.studiedLast(14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DepthCard(
            entranceIndex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Cards learned per deck',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (top.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Create a deck to see progress.'),
                    ),
                  )
                else
                  SimpleBarChart(
                    values: top.map((d) => d.knownCount).toList(),
                    labels: top.map((d) => d.title).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final int index, value;
  final IconData icon;
  final Color color;
  final String label;
  const _StatBox({
    required this.index,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Expanded(
      child: DepthCard(
        entranceIndex: index,
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            CountUp(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
