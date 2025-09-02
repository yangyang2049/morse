import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TelegraphCodeEntry {
  final String code; // 4-digit string 0001..9999
  final String character; // Chinese character

  TelegraphCodeEntry({required this.code, required this.character});
}

class TelegraphCodeService {
  static final TelegraphCodeService _instance = TelegraphCodeService._internal();
  factory TelegraphCodeService() => _instance;
  TelegraphCodeService._internal();

  List<TelegraphCodeEntry>? _cache;

  Future<List<TelegraphCodeEntry>> loadAll() async {
    if (_cache != null) return _cache!;

    final List<TelegraphCodeEntry> entries = [];

    Future<void> loadFrom(String assetPath) async {
      final jsonStr = await rootBundle.loadString(assetPath);
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final code = (map['code'] ?? '').toString().padLeft(4, '0');
        final ch = (map['character'] ?? '').toString();
        if (code.isNotEmpty && ch.isNotEmpty) {
          entries.add(TelegraphCodeEntry(code: code, character: ch));
        }
      }
    }

    // Load assets (prefer full if present, then extended, then base)
    try {
      await loadFrom('assets/chinese_telegraph_codes_full.json');
    } catch (_) {
      // ignore
    }
    try {
      await loadFrom('assets/chinese_telegraph_codes_extended.json');
    } catch (_) {
      // ignore
    }
    try {
      await loadFrom('assets/chinese_telegraph_codes.json');
    } catch (_) {
      // ignore
    }

    // Deduplicate by code, prefer first occurrence
    final Map<String, TelegraphCodeEntry> byCode = {};
    for (final e in entries) {
      byCode.putIfAbsent(e.code, () => e);
    }

    final list = byCode.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));

    _cache = list;
    return list;
  }
}
