import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_themes.dart';
import '../models.dart';
import 'image_service.dart';

/// Holds auth + all deck/card data and persists it per user.
class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;

  UserAccount? user;
  List<Deck> decks = [];
  Map<String, int> activity = {}; // 'yyyy-MM-dd' -> cards studied
  String themeId = 'light';
  int _idCounter = 0;

  bool get isLoggedIn => user != null;

  // ---------------------------------------------------------------- startup
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    themeId = AppThemes.byId(_prefs.getString('app_theme')).id;
    await _ensureDemoAccount();

    final sessionId = _prefs.getString('session');
    if (sessionId != null) {
      final match = _readUsers().where((u) => u.id == sessionId);
      if (match.isNotEmpty) {
        user = match.first;
        _loadData();
      }
    }
  }

  Future<void> setTheme(String id) async {
    final theme = AppThemes.byId(id);
    await _prefs.setString('app_theme', theme.id);
    themeId = theme.id;
    notifyListeners();
  }

  // ------------------------------------------------------------------- auth
  List<UserAccount> _readUsers() {
    final raw = _prefs.getString('users');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _ensureDemoAccount() async {
    final users = _readUsers();
    if (users.any((u) => u.username == 'demo')) return;

    const password = 'demo123';
    final salt = _newSalt();
    users.add(
      UserAccount(
        id: _newId(),
        username: 'demo',
        displayName: 'Demo User',
        salt: salt,
        hash: _hash(password, salt),
      ),
    );
    await _writeUsers(users);
  }

  Future<void> _writeUsers(List<UserAccount> users) => _prefs.setString(
    'users',
    jsonEncode(users.map((u) => u.toJson()).toList()),
  );

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  String _newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Returns an error message, or null on success.
  Future<String?> register(
    String username,
    String password,
    String displayName,
  ) async {
    final name = username.trim().toLowerCase();
    final users = _readUsers();
    if (users.any((u) => u.username == name)) {
      return 'That username is already taken.';
    }
    final salt = _newSalt();
    final account = UserAccount(
      id: _newId(),
      username: name,
      displayName: displayName.trim().isEmpty
          ? username.trim()
          : displayName.trim(),
      salt: salt,
      hash: _hash(password, salt),
    );
    users.add(account);
    await _writeUsers(users);
    await _startSession(account);
    return null;
  }

  /// Returns an error message, or null on success.
  Future<String?> login(String username, String password) async {
    final name = username.trim().toLowerCase();
    final match = _readUsers().where((u) => u.username == name);
    if (match.isEmpty ||
        match.first.hash != _hash(password, match.first.salt)) {
      return 'Incorrect username or password.';
    }
    await _startSession(match.first);
    return null;
  }

  Future<void> _startSession(UserAccount account) async {
    user = account;
    await _prefs.setString('session', account.id);
    _loadData();
    notifyListeners();
  }

  Future<void> logout() async {
    user = null;
    decks = [];
    activity = {};
    await _prefs.remove('session');
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final u = user;
    if (u == null) return;
    for (final d in decks) {
      _deleteDeckImages(d);
    }
    final users = _readUsers()..removeWhere((x) => x.id == u.id);
    await _writeUsers(users);
    await _prefs.remove('data_${u.id}');
    await logout();
  }

  // ------------------------------------------------------------ persistence
  void _loadData() {
    decks = [];
    activity = {};
    final raw = _prefs.getString('data_${user!.id}');
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    decks = (map['decks'] as List? ?? [])
        .map((e) => Deck.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    activity = Map<String, int>.from(map['activity'] ?? {});
  }

  void _save() {
    if (user != null) {
      _prefs.setString(
        'data_${user!.id}',
        jsonEncode({
          'decks': decks.map((d) => d.toJson()).toList(),
          'activity': activity,
        }),
      );
    }
    notifyListeners();
  }

  // ---------------------------------------------------------- deck CRUD
  Deck? deckById(String id) {
    for (final d in decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Returns the new deck's id.
  String addDeck(String title, String description, {String? image}) {
    final deck = Deck(
      id: _newId(),
      title: title,
      description: description,
      imagePath: image,
    );
    decks.add(deck);
    _save();
    return deck.id;
  }

  void updateDeck(String id, String title, String description, String? image) {
    final d = deckById(id);
    if (d == null) return;
    if (d.imagePath != image) ImageService.delete(d.imagePath);
    d.title = title;
    d.description = description;
    d.imagePath = image;
    _save();
  }

  void setShuffle(String deckId, bool value) {
    final d = deckById(deckId);
    if (d == null) return;
    d.shuffle = value;
    _save();
  }

  void deleteDeck(String id) {
    final d = deckById(id);
    if (d != null) _deleteDeckImages(d);
    decks.removeWhere((x) => x.id == id);
    _save();
  }

  void _deleteDeckImages(Deck d) {
    ImageService.delete(d.imagePath);
    for (final c in d.cards) {
      ImageService.delete(c.imagePath);
    }
  }

  /// Makes a full copy of a deck (cards and images included).
  Future<void> duplicateDeck(String id) async {
    final src = deckById(id);
    if (src == null) return;
    final cards = <Flashcard>[];
    for (final c in src.cards) {
      cards.add(
        Flashcard(
          id: _newId(),
          front: c.front,
          back: c.back,
          imagePath: await ImageService.duplicate(c.imagePath),
        ),
      );
    }
    decks.add(
      Deck(
        id: _newId(),
        title: '${src.title} (copy)',
        description: src.description,
        imagePath: await ImageService.duplicate(src.imagePath),
        shuffle: src.shuffle,
        cards: cards,
      ),
    );
    _save();
  }

  // ---------------------------------------------------------- card CRUD
  void addCard(String deckId, String front, String back, {String? image}) {
    deckById(deckId)?.cards.add(
      Flashcard(id: _newId(), front: front, back: back, imagePath: image),
    );
    _save();
  }

  void updateCard(
    String deckId,
    String cardId,
    String front,
    String back,
    String? image,
  ) {
    final deck = deckById(deckId);
    if (deck == null) return;
    for (final c in deck.cards) {
      if (c.id == cardId) {
        if (c.imagePath != image) ImageService.delete(c.imagePath);
        c.front = front;
        c.back = back;
        c.imagePath = image;
      }
    }
    _save();
  }

  void deleteCard(String deckId, String cardId) {
    final deck = deckById(deckId);
    if (deck == null) return;
    for (final c in deck.cards.where((c) => c.id == cardId)) {
      ImageService.delete(c.imagePath);
    }
    deck.cards.removeWhere((c) => c.id == cardId);
    _save();
  }

  /// Copies the chosen cards from one deck into another (originals stay).
  Future<void> copyCards(
    String fromDeckId,
    Set<String> cardIds,
    String toDeckId,
  ) async {
    final from = deckById(fromDeckId);
    final to = deckById(toDeckId);
    if (from == null || to == null) return;
    for (final c in from.cards.where((c) => cardIds.contains(c.id)).toList()) {
      to.cards.add(
        Flashcard(
          id: _newId(),
          front: c.front,
          back: c.back,
          imagePath: await ImageService.duplicate(c.imagePath),
        ),
      );
    }
    _save();
  }

  // ------------------------------------------------------ export / import
  /// Turns decks (or only [onlyCardIds] of them) into shareable JSON text.
  Future<String> exportJson(
    List<Deck> list, {
    Set<String>? onlyCardIds,
    bool includeImages = true,
  }) async {
    final out = <Map<String, dynamic>>[];
    for (final d in list) {
      final cards = <Map<String, dynamic>>[];
      for (final c in d.cards) {
        if (onlyCardIds != null && !onlyCardIds.contains(c.id)) continue;
        cards.add({
          'front': c.front,
          'back': c.back,
          if (includeImages) 'image': await ImageService.toExport(c.imagePath),
        });
      }
      out.add({
        'title': d.title,
        'description': d.description,
        'shuffle': d.shuffle,
        if (includeImages) 'image': await ImageService.toExport(d.imagePath),
        'cards': cards,
      });
    }
    return jsonEncode({'app': 'BrainHumor', 'version': 1, 'decks': out});
  }

  /// Imports exported text. With [intoDeckId], all cards are added to that
  /// deck; otherwise each exported deck becomes a new deck.
  /// Throws [FormatException] with a friendly message on bad input.
  Future<({int decks, int cards})> importJson(
    String text, {
    String? intoDeckId,
  }) async {
    const bad = FormatException(
      'That text is not valid Brain Humor data. Paste the full exported text.',
    );
    dynamic data;
    try {
      data = jsonDecode(text.trim());
    } catch (_) {
      throw bad;
    }
    if (data is! Map || data['app'] != 'BrainHumor' || data['decks'] is! List) {
      throw bad;
    }

    final target = intoDeckId == null ? null : deckById(intoDeckId);
    var deckCount = 0;
    var cardCount = 0;
    try {
      for (final raw in data['decks'] as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        final cards = <Flashcard>[];
        for (final cr in (m['cards'] as List? ?? [])) {
          final cm = Map<String, dynamic>.from(cr as Map);
          cards.add(
            Flashcard(
              id: _newId(),
              front: '${cm['front'] ?? ''}',
              back: '${cm['back'] ?? ''}',
              imagePath: await ImageService.fromExport(cm['image']),
            ),
          );
        }
        cardCount += cards.length;
        if (target != null) {
          target.cards.addAll(cards);
        } else {
          decks.add(
            Deck(
              id: _newId(),
              title: '${m['title'] ?? 'Imported deck'}',
              description: '${m['description'] ?? ''}',
              shuffle: m['shuffle'] is bool ? m['shuffle'] : true,
              imagePath: await ImageService.fromExport(m['image']),
              cards: cards,
            ),
          );
          deckCount++;
        }
      }
    } on TypeError {
      throw bad;
    }
    _save();
    return (decks: deckCount, cards: cardCount);
  }

  // ------------------------------------------------------------- studying
  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void recordStudy(String deckId, String cardId, bool known) {
    final deck = deckById(deckId);
    if (deck == null) return;
    for (final c in deck.cards) {
      if (c.id == cardId) c.known = known;
    }
    deck.lastStudied = DateTime.now();
    final key = _dayKey(DateTime.now());
    activity[key] = (activity[key] ?? 0) + 1;
    _save();
  }

  /// Cards studied per day for the last [days] days (oldest first).
  List<int> studiedLast(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      return activity[_dayKey(day)] ?? 0;
    });
  }

  /// The deck to show under "Continue": last studied, else first deck.
  Deck? get continueDeck {
    final studied = decks.where((d) => d.lastStudied != null).toList()
      ..sort((a, b) => b.lastStudied!.compareTo(a.lastStudied!));
    if (studied.isNotEmpty) return studied.first;
    return decks.isEmpty ? null : decks.first;
  }

  int get totalCards => decks.fold(0, (sum, d) => sum + d.cards.length);
  int get totalKnown => decks.fold(0, (sum, d) => sum + d.knownCount);
}
