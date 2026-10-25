import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';

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
}
