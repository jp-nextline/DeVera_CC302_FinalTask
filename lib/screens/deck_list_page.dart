import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/fancy.dart';
import 'deck_detail_page.dart';

class DeckListPage extends StatefulWidget {
  const DeckListPage({super.key});

  @override
  State<DeckListPage> createState() => _DeckListPageState();
}

class _DeckListPageState extends State<DeckListPage> {
  bool _editMode = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _create() async {
    final r = await showItemDialog(
      context,
      title: 'New deck',
      label1: 'Deck title',
      label2: 'Description',
    );
    if (r != null && mounted) {
      context.read<AppState>().addDeck(r.title, r.body, image: r.image);
    }
  }

  Future<void> _edit(Deck deck) async {
    final r = await showItemDialog(
      context,
      title: 'Edit deck',
      label1: 'Deck title',
      label2: 'Description',
      initial1: deck.title,
      initial2: deck.description,
      initialImage: deck.imagePath,
    );
    if (r != null && mounted) {
      context.read<AppState>().updateDeck(deck.id, r.title, r.body, r.image);
    }
  }

  Future<void> _delete(Deck deck) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete deck?',
      message:
          '"${deck.title}" and its ${deck.cards.length} cards will be removed.',
    );
    if (ok && mounted) context.read<AppState>().deleteDeck(deck.id);
  }

  Future<void> _duplicate(Deck deck) async {
    await context.read<AppState>().duplicateDeck(deck.id);
    if (mounted) _snack('Deck duplicated.');
  }

  Future<void> _export(List<Deck> decks, String title) async {
    final state = context.read<AppState>();
    await showExportDialog(
      context,
      title: title,
      summary:
          '${decks.length} deck(s) will be copied as text you can save or send to someone else.',
      build: (withImages) => state.exportJson(decks, includeImages: withImages),
    );
  }

  Future<void> _import() async {
    final text = await showImportDialog(
      context,
      title: 'Import decks',
      hint:
          'Paste text exported from Brain Humor. Each deck in it becomes a new deck.',
    );
    if (text == null || !mounted) return;
    try {
      final r = await context.read<AppState>().importJson(text);
      if (mounted) _snack('Imported ${r.decks} deck(s) with ${r.cards} cards.');
    } on FormatException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return GradientScaffold(
      useGradient: false,
      title: Text(_editMode ? 'Decks (editing)' : 'Decks'),
      actions: [
        if (_editMode)
          TextButton(
            onPressed: () => setState(() => _editMode = false),
            child: const Text('Done'),
          ),
      ],
      body: state.decks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No decks yet.\nTap the + button to create or import one!',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 270,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: state.decks.length,
              itemBuilder: (_, i) {
                final deck = state.decks[i];
                return _DeckTile(
                  deck: deck,
                  index: i,
                  editMode: _editMode,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeckDetailPage(deckId: deck.id),
                    ),
                  ),
                  onEdit: () => _edit(deck),
                  onDuplicate: () => _duplicate(deck),
                  onExport: () => _export([deck], 'Export "${deck.title}"'),
                  onDelete: () => _delete(deck),
                );
              },
            ),
      floatingActionButton: Bounce(
        scale: 0.88,
        child: PopupMenuButton<String>(
          tooltip: 'Create / Edit',
          onSelected: (v) {
            switch (v) {
              case 'create':
                _create();
              case 'import':
                _import();
              case 'export':
                _export(state.decks, 'Export all decks');
              default:
                setState(() => _editMode = !_editMode);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'create', child: Text('Create')),
            PopupMenuItem(
              value: 'edit',
              child: Text(_editMode ? 'Done editing' : 'Edit'),
            ),
            const PopupMenuItem(value: 'import', child: Text('Import decks')),
            if (state.decks.isNotEmpty)
              const PopupMenuItem(value: 'export', child: Text('Export all')),
          ],
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withAlpha(120),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.add, color: onColor(cs.primary), size: 30),
          ),
        ),
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  final Deck deck;
  final int index;
  final bool editMode;
  final VoidCallback onTap, onEdit, onDuplicate, onExport, onDelete;

  const _DeckTile({
    required this.deck,
    required this.index,
    required this.editMode,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = context.appPalette;
    final pairs = [
      [palette.blue, palette.purple],
      [palette.purple, palette.blue],
      [const Color(0xFF2F7DF0), const Color(0xFF1FA2C4)],
    ];
    final c = pairs[index % pairs.length];
    final hasImage = deck.imagePath != null;
    final fg = hasImage ? Colors.white : onColor(c[0]);

    return DepthCard(
      padding: EdgeInsets.zero,
      entranceIndex: index,
      gradient: c,
      onTap: editMode ? onEdit : onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage) ...[
            AppImage(deck.imagePath),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(200),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // leave room for the edit-mode menu button
                  padding: EdgeInsets.only(right: editMode ? 32 : 0),
                  child: Text(
                    deck.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    deck.description,
                    overflow: TextOverflow.fade,
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(90),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${deck.cards.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (editMode)
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: fg),
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'duplicate':
                      onDuplicate();
                    case 'export':
                      onExport();
                    default:
                      onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(value: 'export', child: Text('Export')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
