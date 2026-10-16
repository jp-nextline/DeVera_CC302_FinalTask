import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/image_service.dart';
import 'fancy.dart';

// ======================================================= item (deck / card)
class ItemResult {
  final String title;
  final String body;
  final String? image;
  const ItemResult(this.title, this.body, this.image);
}

/// Dialog for creating/editing a deck or a card: two text fields + an image.
/// Returns null if cancelled.
Future<ItemResult?> showItemDialog(
  BuildContext context, {
  required String title,
  required String label1,
  required String label2,
  String initial1 = '',
  String initial2 = '',
  String? initialImage,
  bool requireSecond = false,
}) {
  return showDialog<ItemResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ItemDialog(
      title: title,
      label1: label1,
      label2: label2,
      initial1: initial1,
      initial2: initial2,
      initialImage: initialImage,
      requireSecond: requireSecond,
    ),
  );
}

class _ItemDialog extends StatefulWidget {
  final String title, label1, label2, initial1, initial2;
  final String? initialImage;
  final bool requireSecond;

  const _ItemDialog({
    required this.title,
    required this.label1,
    required this.label2,
    required this.initial1,
    required this.initial2,
    required this.initialImage,
    required this.requireSecond,
  });

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _c1 =
      TextEditingController(text: widget.initial1);
  late final TextEditingController _c2 =
      TextEditingController(text: widget.initial2);

  late String? _image = widget.initialImage;
  final List<String> _picked = []; // images picked during this dialog
  String? _error;

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final name = await ImageService.pick(source);
      if (name == null || !mounted) return;
      setState(() {
        _error = null;
        _picked.add(name);
        _image = name;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the picture. Check permissions.');
      }
    }
  }

  void _cleanupPicked({String? keep}) {
    for (final p in _picked) {
      if (p != keep) ImageService.delete(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---- image area ----
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36, color: cs.primary),
                            const SizedBox(height: 4),
                            const Text('Add image (optional)'),
                          ],
                        )
                      : AppImage(_image, fit: BoxFit.cover),
                ),
              ),
              if (_image != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Change')),
                    TextButton.icon(
                        onPressed: () => setState(() => _image = null),
                        icon: const Icon(Icons.close),
                        label: const Text('Remove')),
                  ],
                ),
              if (_error != null)
                Text(_error!, style: TextStyle(color: cs.error)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _c1,
                minLines: 1,
                maxLines: 4,
                decoration: appInputDecoration(context, widget.label1),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _c2,
                minLines: 2,
                maxLines: 6,
                decoration: appInputDecoration(context, widget.label2),
                validator: widget.requireSecond ? _required : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _cleanupPicked(); // discard pictures chosen in this dialog
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _cleanupPicked(keep: _image);
              Navigator.pop(
                  context, ItemResult(_c1.text.trim(), _c2.text.trim(), _image));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================== confirm
Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    String action = 'Delete'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action)),
      ],
    ),
  );
  return result ?? false;
}

// ============================================================== import
/// Asks the user to paste exported text. Returns the text or null.
Future<String?> showImportDialog(BuildContext context,
    {required String title, required String hint}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ImportDialog(title: title, hint: hint),
  );
}

class _ImportDialog extends StatefulWidget {
  final String title, hint;
  const _ImportDialog({required this.title, required this.hint});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) setState(() => _c.text = data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.hint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          TextField(
            controller: _c,
            minLines: 4,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: appInputDecoration(context, 'Paste exported text here'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste from clipboard')),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed:
              _c.text.trim().isEmpty ? null : () => Navigator.pop(context, _c.text),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

// ============================================================== export
/// Lets the user choose whether to include images, then copies the exported
/// text to the clipboard.
Future<void> showExportDialog(
  BuildContext context, {
  required String title,
  required String summary,
  required Future<String> Function(bool includeImages) build,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showDialog<void>(
    context: context,
    builder: (_) => _ExportDialog(
        title: title, summary: summary, build: build, messenger: messenger),
  );
}

class _ExportDialog extends StatefulWidget {
  final String title, summary;
  final Future<String> Function(bool) build;
  final ScaffoldMessengerState messenger;
  const _ExportDialog({
    required this.title,
    required this.summary,
    required this.build,
    required this.messenger,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  bool _images = true;
  bool _busy = false;

  Future<void> _copy() async {
    setState(() => _busy = true);
    final text = await widget.build(_images);
    await Clipboard.setData(ClipboardData(text: text));
    widget.messenger.showSnackBar(const SnackBar(
        content: Text('Copied! Paste it anywhere to save or share it.')));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.summary),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include images'),
            subtitle: const Text('Makes the text much longer'),
            value: _images,
            onChanged: _busy ? null : (v) => setState(() => _images = v),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _busy ? null : _copy,
          icon: const Icon(Icons.copy),
          label: Text(_busy ? 'Preparing...' : 'Copy to clipboard'),
        ),
      ],
    );
  }
}

// ========================================================= deck picker
const String kNewDeck = '__new_deck__';

/// Lets the user choose a destination deck. Returns a deck id, [kNewDeck],
/// or null if cancelled.
Future<String?> showDeckPicker(BuildContext context,
    {required String title, required List<Deck> decks}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('New deck'),
          onTap: () => Navigator.pop(ctx, kNewDeck),
        ),
        for (final d in decks)
          ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: d.imagePath != null
                    ? AppImage(d.imagePath)
                    : Container(
                        color: Theme.of(ctx).colorScheme.primaryContainer,
                        child: const Icon(Icons.style)),
              ),
            ),
            title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${d.cards.length} cards'),
            onTap: () => Navigator.pop(ctx, d.id),
          ),
      ],
    ),
  );
}
