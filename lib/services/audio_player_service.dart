import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import 'quran_api_service.dart';
import 'storage_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final QuranApiService _api = QuranApiService();
  final StorageService storage = StorageService();

  Surah? _currentSurah;
  List<Surah> _queue = [];
  int _queueIndex = 0;
  String _reciter = 'ar.alafasy';
  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;
  Timer? _positionSaveTimer;

  Surah? get currentSurah => _currentSurah;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get totalDuration => _player.duration;
  Stream<Duration> get positionStream => _player.positionStream;
  String get reciter => _reciter;
  Duration? get sleepTimerDuration => _sleepTimerDuration;

  AudioPlayerService() {
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
    _positionSaveTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
  }

  void _savePosition() {
    if (_currentSurah != null) {
      storage.saveLastPlayed(
        surahNumber: _currentSurah!.number,
        reciter: _reciter,
        positionMs: _player.position.inMilliseconds,
      );
    }
  }

  void setReciter(String reciterId) {
    _reciter = reciterId;
    notifyListeners();
  }

  Future<void> playSurah(Surah surah,
      {List<Surah>? queue, Duration? startAt}) async {
    _currentSurah = surah;
    if (queue != null) {
      _queue = queue;
      _queueIndex = queue.indexWhere((s) => s.number == surah.number);
    }

    final localPath =
        await storage.localPathIfDownloaded(_reciter, surah.number);
    if (localPath != null) {
      await _player.setFilePath(localPath);
    } else {
      final url = _api.audioUrlFor(surah.number, reciter: _reciter);
      await _player.setUrl(url);
    }

    if (startAt != null) {
      await _player.seek(startAt);
    }
    await _player.play();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty || _queueIndex >= _queue.length - 1) return;
    _queueIndex++;
    await playSurah(_queue[_queueIndex], queue: _queue);
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty || _queueIndex <= 0) return;
    _queueIndex--;
    await playSurah(_queue[_queueIndex], queue: _queue);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    _sleepTimer = Timer(duration, () {
      _player.pause();
      _sleepTimerDuration = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerDuration = null;
    notifyListeners();
  }

  String audioUrlForDownload(int surahNumber) =>
      _api.audioUrlFor(surahNumber, reciter: _reciter);

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSaveTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
