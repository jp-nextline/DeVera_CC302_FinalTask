import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../widgets/dialogs.dart';
import '../widgets/fancy.dart';
import 'study_page.dart';

class DeckDetailPage extends StatefulWidget {
  final String deckId;
  const DeckDetailPage({super.key, required this.deckId});

  @override
  State<DeckDetailPage> createState() => _DeckDetailPageState();
}

class _DeckDetailPageState extends State<DeckDetailPage> {
  bool _selectMode = false;
  final Set<String> _selected = {};

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  void _exitSelect() => setState(() {
        _selectMode = false;
        _selected.clear();
      });

  void _toggle(String cardId) => setState(() {
        _selected.contains(cardId)
            ? _selected.remove(cardId)
            : _selected.add(cardId);
      });

  // ------------------------------------------------------------ deck actions
  Future<void> _editDeck(Deck deck) async {
    final r = await showItemDialog(context,
        title: 'Edit deck',
        label1: 'Deck title',
        label2: 'Description',
        initial1: deck.title,
        initial2: deck.description,
        initialImage: deck.imagePath);
    if (r != null && mounted) {
      context.read<AppState>().updateDeck(deck.id, r.title, r.body, r.image);
    }
  }

  Future<void> _deleteDeck(Deck deck) async {
    final ok = await confirmDialog(context,
        title: 'Delete deck?',
        message: '"${deck.title}" and all its cards will be removed.');
    if (ok && mounted) {
      context.read<AppState>().deleteDeck(deck.id);
      Navigator.pop(context);
    }
  }

  Future<void> _duplicateDeck(Deck deck) async {
    await context.read<AppState>().duplicateDeck(deck.id);
    if (mounted) _snack('Deck duplicated. Find the copy in your deck list.');
  }

  Future<void> _exportDeck(Deck deck, {Set<String>? only}) async {
    final state = context.read<AppState>();
    final count = only?.length ?? deck.cards.length;
    await showExportDialog(
      context,
      title: only == null ? 'Export deck' : 'Export selected cards',
      summary: '$count card(s) from "${deck.title}" will be copied as text.',
      build: (withImages) => state.exportJson([deck],
          onlyCardIds: only, includeImages: withImages),
    );
    if (only != null && mounted) _exitSelect();
  }

  Future<void> _importCards(Deck deck) async {
    final text = await showImportDialog(context,
        title: 'Import cards',
        hint:
            'Paste text exported from Brain Humor. All of its cards are added to "${deck.title}".');
    if (text == null || !mounted) return;
    try {
      final r = await context
          .read<AppState>()
          .importJson(text, intoDeckId: deck.id);
      if (mounted) _snack('Added ${r.cards} card(s) to this deck.');
    } on FormatException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _copySelected(Deck deck) async {
    final state = context.read<AppState>();
    final others = state.decks.where((d) => d.id != deck.id).toList();
    final target = await showDeckPicker(context,
        title: 'Copy ${_selected.length} card(s) to...', decks: others);
    if (target == null || !mounted) return;

    var targetId = target;
    var targetName = state.deckById(target)?.title ?? '';
    if (target == kNewDeck) {
      targetName = '${deck.title} (selection)';
      targetId = state.addDeck(targetName, '');
    }
    final count = _selected.length;
    await state.copyCards(deck.id, {..._selected}, targetId);
    if (mounted) {
      _snack('Copied $count card(s) to "$targetName".');
      _exitSelect();
    }
  }

  // ------------------------------------------------------------ card actions
  Future<void> _addCard(Deck deck) async {
    final r = await showItemDialog(context,
        title: 'New card',
        label1: 'Front (question)',
        label2: 'Back (answer)',
        requireSecond: true);
    if (r != null && mounted) {
      context.read<AppState>().addCard(deck.id, r.title, r.body, image: r.image);
    }
  }

  Future<void> _editCard(Deck deck, Flashcard c) async {
    final r = await showItemDialog(context,
        title: 'Edit card',
        label1: 'Front (question)',
        label2: 'Back (answer)',
        initial1: c.front,
        initial2: c.back,
        initialImage: c.imagePath,
        requireSecond: true);
    if (r != null && mounted) {
      context
          .read<AppState>()
          .updateCard(deck.id, c.id, r.title, r.body, r.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final deck = state.deckById(widget.deckId);
    if (deck == null) {
      return const GradientScaffold(
          title: Text(''), body: Center(child: Text('Deck not found.')));
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GradientScaffold(
      leading: _selectMode
          ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelect)
          : null,
      title: Text(
          _selectMode ? '${_selected.length} selected' : deck.title,
          overflow: TextOverflow.ellipsis),
      actions: _selectMode
          ? [
              IconButton(
                tooltip: 'Select all',
                icon: const Icon(Icons.select_all),
                onPressed: () => setState(
                    () => _selected.addAll(deck.cards.map((c) => c.id))),
              ),
              IconButton(
                tooltip: 'Copy to another deck',
                icon: const Icon(Icons.copy_all),
                onPressed:
                    _selected.isEmpty ? null : () => _copySelected(deck),
              ),
              IconButton(
                tooltip: 'Export selected',
                icon: const Icon(Icons.ios_share),
                onPressed: _selected.isEmpty
                    ? null
                    : () => _exportDeck(deck, only: {..._selected}),
              ),
            ]
          : [
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      _editDeck(deck);
                    case 'select':
                      setState(() => _selectMode = true);
                    case 'duplicate':
                      _duplicateDeck(deck);
                    case 'export':
                      _exportDeck(deck);
                    case 'import':
                      _importCards(deck);
                    default:
                      _deleteDeck(deck);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit deck')),
                  PopupMenuItem(value: 'select', child: Text('Select cards')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate deck')),
                  PopupMenuItem(value: 'export', child: Text('Export deck')),
                  PopupMenuItem(value: 'import', child: Text('Import cards')),
                  PopupMenuItem(value: 'delete', child: Text('Delete deck')),
                ],
              ),
            ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (deck.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DepthCard(
                padding: EdgeInsets.zero,
                child: AspectRatio(
                    aspectRatio: 16 / 9, child: AppImage(deck.imagePath)),
              ),
            ),
          if (deck.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(deck.description, style: theme.textTheme.bodyLarge),
            ),
          DepthCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            radius: 18,
            child: SwitchListTile(
              secondary: const Icon(Icons.shuffle),
              title: const Text('Shuffle cards when studying'),
              value: deck.shuffle,
              onChanged: (v) => state.setShuffle(deck.id, v),
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            icon: Icons.play_arrow_rounded,
            label: 'Study ${deck.cards.length} cards',
            expand: true,
            onPressed: deck.cards.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StudyPage(deckId: deck.id))),
          ),
          const SizedBox(height: 16),
          if (deck.cards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('No cards yet. Tap "Add card" or import some.')),
            ),
          for (final (i, c) in deck.cards.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DepthCard(
                padding: const EdgeInsets.all(10),
                entranceIndex: i,
                radius: 18,
                color: _selected.contains(c.id) ? cs.primaryContainer : null,
                onTap: () => _selectMode ? _toggle(c.id) : _editCard(deck, c),
                onLongPress: () {
                  setState(() => _selectMode = true);
                  _toggle(c.id);
                },
                child: Row(
                  children: [
                    if (_selectMode)
                      Checkbox(
                          value: _selected.contains(c.id),
                          onChanged: (_) => _toggle(c.id))
                    else if (c.imagePath != null)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImage(c.imagePath)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          c.known
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: c.known ? Colors.green : null,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.front,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(c.back,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (!_selectMode)
                      IconButton(
                        tooltip: 'Delete card',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            context.read<AppState>().deleteCard(deck.id, c.id),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : Bounce(
              child: FloatingActionButton.extended(
                onPressed: () => _addCard(deck),
                icon: const Icon(Icons.add),
                label: const Text('Add card'),
              ),
            ),
    );
  }
}
