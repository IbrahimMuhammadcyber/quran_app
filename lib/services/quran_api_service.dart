import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';

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

  // Redirect-based endpoint: resolves the correct file/bitrate per reciter
  // automatically, instead of guessing a bitrate ourselves.
  String audioUrlFor(int surahNumber, {String reciter = 'ar.alafasy'}) {
    return 'https://api.islamic.app/v1/audio/surah/$reciter/$surahNumber';
  }

  /// Fetches Arabic text (Uthmani script) + English translation (Sahih
  /// International) for every verse in a surah, paired up by position.
  Future<List<Ayah>> fetchVerses(int surahNumber) async {
    final url = Uri.parse(
        '$_baseUrl/surah/$surahNumber/editions/quran-uthmani,en.sahih');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load verses (${response.statusCode})');
    }

    final data = json.decode(response.body);
    final List<dynamic> editions = data['data'];
    final arabicAyahs = editions[0]['ayahs'] as List<dynamic>;
    final translationAyahs = editions[1]['ayahs'] as List<dynamic>;

    final List<Ayah> result = [];
    for (var i = 0; i < arabicAyahs.length; i++) {
      result.add(Ayah(
        numberInSurah: arabicAyahs[i]['numberInSurah'],
        arabicText: arabicAyahs[i]['text'],
        translation: translationAyahs[i]['text'],
      ));
    }
    return result;
  }
}
