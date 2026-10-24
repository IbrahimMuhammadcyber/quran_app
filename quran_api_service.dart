import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';

/// Wraps the free alquran.cloud API. Swap this out for a bundled local
/// JSON file (assets/data/surahs.json) if you want the surah list to
/// work fully offline.
class QuranApiService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<List<Surah>> fetchSurahList() async {
    final response = await http.get(Uri.parse('$_baseUrl/surah'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load surah list (${response.statusCode})');
    }

    final data = json.decode(response.body);
    final List<dynamic> surahs = data['data'];
    return surahs.map((s) => Surah.fromJson(s)).toList();
  }

  /// Reciter identifiers follow alquran.cloud's edition codes,
  /// e.g. "ar.alafasy" for Mishary Alafasy.
  String audioUrlFor(int surahNumber, {String reciter = 'ar.alafasy'}) {
    return 'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$surahNumber.mp3';
  }
}
