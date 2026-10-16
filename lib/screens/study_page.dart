import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/fancy.dart';

class StudyPage extends StatefulWidget {
  final String deckId;
  const StudyPage({super.key, required this.deckId});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late List<Flashcard> _queue;
  int _index = 0;
  int _got = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  /// Builds the card order for a round: shuffled only if the deck's
  /// shuffle option is on.
  void _restart() {
    final deck = context.read<AppState>().deckById(widget.deckId);
    _queue = List.of(deck?.cards ?? []);
    if (deck?.shuffle ?? true) _queue.shuffle();
    _index = 0;
    _got = 0;
    _flipped = false;
    _flip.value = 0;
  }

  void _toggleFlip() {
    setState(() => _flipped = !_flipped);
    _flipped ? _flip.forward() : _flip.reverse();
  }

  void _answer(bool known) {
    context.read<AppState>().recordStudy(
      widget.deckId,
      _queue[_index].id,
      known,
    );
    setState(() {
      if (known) _got++;
      _index++;
      _flipped = false;
      _flip.value = 0;
    });
  }

  void _toggleShuffle(Deck deck) {
    context.read<AppState>().setShuffle(deck.id, !deck.shuffle);
    setState(_restart); // start a fresh round in the new order
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          !deck.shuffle
              ? 'Shuffle on - new round started'
              : 'Shuffle off - cards in deck order',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deck = context.watch<AppState>().deckById(widget.deckId);

    return GradientScaffold(
      title: Text(deck?.title ?? 'Study', overflow: TextOverflow.ellipsis),
      actions: [
        if (deck != null)
          IconButton(
            tooltip: deck.shuffle ? 'Shuffle: on' : 'Shuffle: off',
            icon: Icon(
              deck.shuffle ? Icons.shuffle_on_outlined : Icons.shuffle,
            ),
            color: deck.shuffle ? theme.colorScheme.primary : null,
            onPressed: () => _toggleShuffle(deck),
          ),
      ],
      body: _queue.isEmpty
          ? const Center(child: Text('This deck has no cards yet.'))
          : _index >= _queue.length
          ? _summary(theme)
          : _cardView(theme),
    );
  }

  Widget _summary(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DepthCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 84),
              const SizedBox(height: 16),
              Text('Round complete!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'You knew $_got of ${_queue.length} cards.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              GradientButton(
                icon: Icons.replay_rounded,
                label: 'Study again',
                onPressed: () => setState(_restart),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _face(Flashcard card, {required bool back}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = context.appPalette;
    final colors = back
        ? [palette.cyan, palette.blue]
        : [palette.blueLight, palette.purple];
    const fg = Colors.white;
    final showImage = !back && card.imagePath != null;

    return DepthCard(
      gradient: colors,
      radius: 28,
      padding: const EdgeInsets.all(22),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              back ? 'ANSWER' : 'QUESTION',
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg.withAlpha(200),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            if (showImage)
              Flexible(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppImage(card.imagePath, fit: BoxFit.contain),
                ),
              ),
            if (showImage) const SizedBox(height: 12),
            Flexible(
              flex: 2,
              child: SingleChildScrollView(
                child: Text(
                  back ? card.back : card.front,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!back)
              Text(
                'Tap to flip',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withAlpha(200),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardView(ThemeData theme) {
    final card = _queue[_index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _index / _queue.length,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Card ${_index + 1} of ${_queue.length}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: _toggleFlip,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (_, __) {
                  final angle = _flip.value * pi;
                  final showBack = angle > pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012) // perspective
                      ..rotateY(angle),
                    child: showBack
                        // mirror the back face so its text isn't reversed
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _face(card, back: true),
                          )
                        : _face(card, back: false),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: _flipped
                ? Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          outlined: true,
                          expand: true,
                          icon: Icons.refresh_rounded,
                          label: 'Still learning',
                          onPressed: () => _answer(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          expand: true,
                          icon: Icons.check_rounded,
                          label: 'Got it',
                          onPressed: () => _answer(true),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
