class Flashcard {
  final String id;
  String front;
  String back;
  bool known;
  String? imagePath; // file name inside the app's images folder

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.known = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        'known': known,
        'imagePath': imagePath,
      };

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'],
        front: j['front'],
        back: j['back'],
        known: j['known'] ?? false,
        imagePath: j['imagePath'],
      );
}

class Deck {
  final String id;
  String title;
  String description;
  String? imagePath;
  bool shuffle; // shuffle cards when studying this deck
  List<Flashcard> cards;
  DateTime? lastStudied;

  Deck({
    required this.id,
    required this.title,
    this.description = '',
    this.imagePath,
    this.shuffle = true,
    List<Flashcard>? cards,
    this.lastStudied,
  }) : cards = cards ?? [];

  int get knownCount => cards.where((c) => c.known).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imagePath': imagePath,
        'shuffle': shuffle,
        'cards': cards.map((c) => c.toJson()).toList(),
        'lastStudied': lastStudied?.toIso8601String(),
      };

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        id: j['id'],
        title: j['title'],
        description: j['description'] ?? '',
        imagePath: j['imagePath'],
        shuffle: j['shuffle'] ?? true,
        cards: (j['cards'] as List? ?? [])
            .map((e) => Flashcard.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        lastStudied:
            j['lastStudied'] == null ? null : DateTime.parse(j['lastStudied']),
      );
}

class UserAccount {
  final String id;
  final String username;
  String displayName;
  final String salt;
  final String hash;

  UserAccount({
    required this.id,
    required this.username,
    required this.displayName,
    required this.salt,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'salt': salt,
        'hash': hash,
      };

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
        id: j['id'],
        username: j['username'],
        displayName: j['displayName'],
        salt: j['salt'],
        hash: j['hash'],
      );
}
