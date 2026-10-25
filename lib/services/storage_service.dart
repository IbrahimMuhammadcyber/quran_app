import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _lastSurahKey = 'last_surah_number';
  static const _lastReciterKey = 'last_reciter';
  static const _lastPositionKey = 'last_position_ms';
  static const _downloadedKey = 'downloaded_files';

  Future<void> saveLastPlayed({
    required int surahNumber,
    required String reciter,
    required int positionMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSurahKey, surahNumber);
    await prefs.setString(_lastReciterKey, reciter);
    await prefs.setInt(_lastPositionKey, positionMs);
  }

  Future<Map<String, dynamic>?> getLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final surahNumber = prefs.getInt(_lastSurahKey);
    final reciter = prefs.getString(_lastReciterKey);
    final positionMs = prefs.getInt(_lastPositionKey) ?? 0;
    if (surahNumber == null || reciter == null) return null;
    return {
      'surahNumber': surahNumber,
      'reciter': reciter,
      'positionMs': positionMs,
    };
  }

  String _keyFor(String reciter, int surahNumber) => '${reciter}_$surahNumber';

  Future<Directory> _audioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/tilawah_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  Future<String> _localPath(String reciter, int surahNumber) async {
    final dir = await _audioDir();
    return '${dir.path}/${_keyFor(reciter, surahNumber)}.mp3';
  }

  Future<bool> isDownloaded(String reciter, int surahNumber) async {
    final path = await _localPath(reciter, surahNumber);
    return File(path).exists();
  }

  Future<String?> localPathIfDownloaded(
      String reciter, int surahNumber) async {
    final path = await _localPath(reciter, surahNumber);
    if (await File(path).exists()) return path;
    return null;
  }

  Future<void> downloadSurah({
    required String reciter,
    required int surahNumber,
    required String remoteUrl,
    void Function(double progress)? onProgress,
  }) async {
    final path = await _localPath(reciter, surahNumber);
    final request = http.Request('GET', Uri.parse(remoteUrl));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Download failed (${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    int received = 0;
    final file = File(path);
    final sink = file.openWrite();

    await response.stream.listen((chunk) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0 && onProgress != null) {
        onProgress(received / total);
      }
    }).asFuture();

    await sink.close();

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedKey) ?? [];
    final key = _keyFor(reciter, surahNumber);
    if (!list.contains(key)) {
      list.add(key);
      await prefs.setStringList(_downloadedKey, list);
    }
  }

  Future<void> deleteDownload(String reciter, int surahNumber) async {
    final path = await _localPath(reciter, surahNumber);
    final file = File(path);
    if (await file.exists()) await file.delete();

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_downloadedKey) ?? [];
    list.remove(_keyFor(reciter, surahNumber));
    await prefs.setStringList(_downloadedKey, list);
  }
}
