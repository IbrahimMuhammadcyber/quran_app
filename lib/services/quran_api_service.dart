import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/juz_ayah.dart';

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

  String audioUrlFor(int surahNumber, {String reciter = 'ar.alafasy'}) {
    return 'https://api.islamic.app/v1/audio/surah/$reciter/$surahNumber';
  }

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

  /// Short Arabic interpretive commentary (Tafsir Al-Muyassar). Falls back
  /// to an error message rather than throwing, so callers can show it
  /// inline without crashing.
  Future<String> fetchTafsir(int surahNumber, int ayahNumber) async {
    final url =
        Uri.parse('$_baseUrl/ayah/$surahNumber:$ayahNumber/ar.muyassar');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Tafsir not available (${response.statusCode})');
    }

    final data = json.decode(response.body);
    return data['data']['text'] as String;
  }

  /// The juz endpoint does not support combining two editions in one
  /// request the way the surah endpoint does, so Arabic text and
  /// translation are fetched as two separate calls and paired up here.
  Future<List<JuzAyah>> fetchJuz(int juzNumber) async {
    final arabicUrl = Uri.parse('$_baseUrl/juz/$juzNumber/quran-uthmani');
    final translationUrl = Uri.parse('$_baseUrl/juz/$juzNumber/en.sahih');

    final responses = await Future.wait([
      http.get(arabicUrl),
      http.get(translationUrl),
    ]);

    if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
      throw Exception('Failed to load juz');
    }

    final arabicData = json.decode(responses[0].body);
    final translationData = json.decode(responses[1].body);
    final arabicAyahs = arabicData['data']['ayahs'] as List<dynamic>;
    final translationAyahs =
        translationData['data']['ayahs'] as List<dynamic>;

    final List<JuzAyah> result = [];
    for (var i = 0; i < arabicAyahs.length; i++) {
      final a = arabicAyahs[i];
      result.add(JuzAyah(
        surahNumber: a['surah']['number'],
        surahName: a['surah']['englishName'],
        numberInSurah: a['numberInSurah'],
        arabicText: a['text'],
        translation: translationAyahs[i]['text'],
      ));
    }
    return result;
  }
}
