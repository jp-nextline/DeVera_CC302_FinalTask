import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/fancy.dart';
import 'deck_detail_page.dart';
import 'study_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onSeeAllDecks;
  final VoidCallback onNewDeck;
  final VoidCallback onOpenProfile;

  const HomePage({
    super.key,
    required this.onSeeAllDecks,
    required this.onNewDeck,
    required this.onOpenProfile,
  });

  void _open(BuildContext context, Deck d) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DeckDetailPage(deckId: d.id)),
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final current = state.continueDeck;
    final name = state.user?.displayName ?? '';
    final palette = context.appPalette;

    // recent = last studied first, then the rest
    final recent = [...state.decks]
      ..sort((a, b) {
        final ad = a.lastStudied, bd = b.lastStudied;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ---------------------------------------------------- header
          FadeSlideIn(
            index: 0,
            child: Row(
              children: [
                UserAvatar(name: name, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.muted,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ------------------------------------- "card balance" style card
          FadeSlideIn(
            index: 1,
            child: current == null
                ? DepthCard(
                    gradient: [palette.blue, palette.purple],
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No decks yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Create your first deck to start learning.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: 'Create a deck',
                          icon: Icons.add,
                          outlined: true,
                          onPressed: onNewDeck,
                        ),
                      ],
                    ),
                  )
                : _ContinueCard(
                    deck: current,
                    onOpen: () => _open(context, current),
                  ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------- quick action row
          FadeSlideIn(
            index: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxSpacing = ((constraints.maxWidth - 248) / 3).clamp(
                  0.0,
                  36.0,
                );
                final spacing = (constraints.maxWidth * 0.08).clamp(
                  0.0,
                  maxSpacing,
                );
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: spacing,
                  runSpacing: 12,
                  children: [
                    _Action(
                      icon: Icons.play_arrow_rounded,
                      label: 'Study',
                      color: palette.orange,
                      onTap: (current == null || current.cards.isEmpty)
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyPage(deckId: current.id),
                              ),
                            ),
                    ),
                    _Action(
                      icon: Icons.add_rounded,
                      label: 'New deck',
                      color: palette.cyan,
                      onTap: onNewDeck,
                    ),
                    _Action(
                      icon: Icons.view_list_rounded,
                      label: 'Decks',
                      color: palette.green,
                      onTap: onSeeAllDecks,
                    ),
                    _Action(
                      icon: Icons.bar_chart_rounded,
                      label: 'Progress',
                      color: palette.purple,
                      onTap: onOpenProfile,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 26),

          // -------------------------------- "recent transaction" style list
          if (recent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent decks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllDecks,
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final (i, d) in recent.take(3).toList().indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DepthCard(
                  entranceIndex: 3 + i,
                  radius: 20,
                  padding: const EdgeInsets.all(12),
                  onTap: () => _open(context, d),
                  child: Row(
                    children: [
                      _DeckIcon(deck: d, index: i, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${d.cards.length} cards',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.green.withAlpha(36),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          d.cards.isEmpty
                              ? '0%'
                              : '${(d.knownCount * 100 / d.cards.length).round()}%',
                          style: TextStyle(
                            color: palette.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
          ],

          // ------------------------------------ "send money" style avatars
          Text(
            'More!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: state.decks.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _Bubble(
                    label: 'Add',
                    onTap: onNewDeck,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.blueLight.withAlpha(160),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: palette.blueLight,
                        size: 28,
                      ),
                    ),
                  );
                }
                final d = state.decks[i - 1];
                return _Bubble(
                  label: d.title,
                  onTap: () => _open(context, d),
                  child: _DeckIcon(deck: d, index: i, size: 58, circle: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onOpen;
  const _ContinueCard({required this.deck, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.appPalette;
    final hasImage = deck.imagePath != null;
    final percent = deck.cards.isEmpty
        ? 0
        : (deck.knownCount * 100 / deck.cards.length).round();

    return DepthCard(
      padding: EdgeInsets.zero,
      radius: 28,
      gradient: [palette.blueLight, palette.blue, palette.purple],
      onTap: onOpen,
      child: Stack(
        children: [
          // decorative translucent circles, like the card in the reference
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(22),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -60,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(16),
              ),
            ),
          ),
          if (hasImage) ...[
            Positioned.fill(child: AppImage(deck.imagePath)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(70),
                      Colors.black.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.style_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continue learning',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  deck.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (deck.description.isNotEmpty)
                  Text(
                    deck.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CountUp(
                      percent,
                      suffix: '%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${deck.knownCount} of ${deck.cards.length} cards learned',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: deck.cards.isEmpty
                        ? 0
                        : deck.knownCount / deck.cards.length,
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: Colors.white.withAlpha(60),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Bounce(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: palette.blue,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Study',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        onPressed: deck.cards.isEmpty
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudyPage(deckId: deck.id),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Bounce(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: onOpen,
                        child: const Text('Open'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Bounce(
        enabled: onTap != null,
        scale: 0.86,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 80 : 18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 12, color: palette.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deck picture (or a coloured icon when it has no image).
class _DeckIcon extends StatelessWidget {
  final Deck deck;
  final int index;
  final double size;
  final bool circle;
  const _DeckIcon({
    required this.deck,
    required this.index,
    required this.size,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appPalette.colors;
    final color = colors[index % colors.length];
    final radius = circle ? size / 2 : size * 0.3;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: deck.imagePath != null
            ? AppImage(deck.imagePath)
            : Container(
                color: color.withAlpha(48),
                child: Center(
                  child: circle
                      ? Text(
                          deck.title.isEmpty
                              ? '?'
                              : deck.title[0].toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: size * 0.4,
                          ),
                        )
                      : Icon(
                          Icons.style_rounded,
                          color: color,
                          size: size * 0.5,
                        ),
                ),
              ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;
  const _Bubble({
    required this.child,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Bounce(
      scale: 0.88,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          child: Column(
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.appPalette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
