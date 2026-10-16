import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores deck/card images.
///  - Android/iOS/desktop: files inside the app's documents folder.
///  - Web (Chrome): bytes kept in memory and saved in the browser's local
///    storage (small limit, so web is meant for testing only).
/// Only an image NAME is saved in the deck/card data.
class ImageService {
  static late Directory _dir; // not used on web
  static final Map<String, Uint8List> _web = {}; // web only
  static late SharedPreferences _prefs; // web only
  static final ImagePicker _picker = ImagePicker();
  static int _counter = 0;

  static Future<void> init() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
      for (final key in _prefs.getKeys().where((k) => k.startsWith('img_'))) {
        final data = _prefs.getString(key);
        if (data != null) {
          try {
            _web[key.substring(4)] = base64Decode(data);
          } catch (_) {}
        }
      }
      return;
    }
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/images');
    if (!await _dir.exists()) await _dir.create(recursive: true);
  }

  static File file(String name) => File('${_dir.path}/$name');

  /// Web only: the bytes of a stored image.
  static Uint8List? webBytes(String name) => _web[name];

  static String _newName(String ext) =>
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}$ext';

  static String _ext(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || path.length - i > 6) return '.jpg';
    final e = path.substring(i).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(e) ? e : '.jpg';
  }

  static Future<void> _storeBytes(String name, Uint8List bytes) async {
    if (kIsWeb) {
      _web[name] = bytes;
      await _prefs.setString('img_$name', base64Encode(bytes));
    } else {
      await file(name).writeAsBytes(bytes);
    }
  }

  static Future<Uint8List?> _readBytes(String name) async {
    if (kIsWeb) return _web[name];
    final f = file(name);
    return await f.exists() ? await f.readAsBytes() : null;
  }

  /// Opens the gallery/camera, stores the chosen picture and returns its
  /// name (or null if cancelled).
  static Future<String?> pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (x == null) return null;
    final name = _newName(_ext(x.name));
    await _storeBytes(name, await x.readAsBytes());
    return name;
  }

  /// Makes an independent copy of an image (so deleting one never breaks the other).
  static Future<String?> duplicate(String? name) async {
    if (name == null) return null;
    final bytes = await _readBytes(name);
    if (bytes == null) return null;
    final copy = _newName(_ext(name));
    await _storeBytes(copy, bytes);
    return copy;
  }

  static Future<void> delete(String? name) async {
    if (name == null) return;
    if (kIsWeb) {
      _web.remove(name);
      await _prefs.remove('img_$name');
      return;
    }
    final f = file(name);
    if (await f.exists()) await f.delete();
  }

  // ---- export / import (images travel inside the JSON as base64) ----
  static Future<Map<String, String>?> toExport(String? name) async {
    if (name == null) return null;
    final bytes = await _readBytes(name);
    if (bytes == null) return null;
    return {'ext': _ext(name), 'data': base64Encode(bytes)};
  }

  static Future<String?> fromExport(dynamic m) async {
    if (m is! Map || m['data'] is! String) return null;
    var ext = '.jpg';
    // Only allow a plain extension (prevents odd file names from pasted data).
    if (m['ext'] is String && RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(m['ext'])) {
      ext = m['ext'];
    }
    try {
      final name = _newName(ext);
      await _storeBytes(name, base64Decode(m['data']));
      return name;
    } catch (_) {
      return null;
    }
  }
}
