import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import 'quran_api_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final QuranApiService _api = QuranApiService();

  Surah? _currentSurah;
  List<Surah> _queue = [];
  int _queueIndex = 0;
  String _reciter = 'ar.alafasy';
  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;

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
  }

  void setReciter(String reciterId) {
    _reciter = reciterId;
    notifyListeners();
  }

  Future<void> playSurah(Surah surah, {List<Surah>? queue}) async {
    _currentSurah = surah;
    if (queue != null) {
      _queue = queue;
      _queueIndex = queue.indexWhere((s) => s.number == surah.number);
    }
    final url = _api.audioUrlFor(surah.number, reciter: _reciter);
    await _player.setUrl(url);
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

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
