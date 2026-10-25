import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import 'quran_api_service.dart';
import 'storage_service.dart';

enum TilawahRepeatMode { off, all, one }

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final QuranApiService _api = QuranApiService();
  final StorageService storage = StorageService();

  Surah? _currentSurah;
  List<Surah> _queue = [];
  List<int> _playOrder = [];
  int _orderPos = 0;
  String _reciter = 'ar.alafasy';
  TilawahRepeatMode _repeatMode = TilawahRepeatMode.off;
  bool _shuffle = false;

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
  TilawahRepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffle;

  AudioPlayerService() {
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        _onTrackComplete();
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

  void _rebuildOrder({bool keepCurrent = false}) {
    final currentIndex =
        _currentSurah != null ? _queue.indexOf(_currentSurah!) : -1;
    final indices = List<int>.generate(_queue.length, (i) => i);
    if (_shuffle) indices.shuffle();
    _playOrder = indices;
    if (keepCurrent && currentIndex != -1) {
      final pos = _playOrder.indexOf(currentIndex);
      _orderPos = pos == -1 ? 0 : pos;
    } else {
      _orderPos = 0;
    }
  }

  Future<void> playSurah(Surah surah,
      {List<Surah>? queue, Duration? startAt}) async {
    _currentSurah = surah;
    if (queue != null) {
      _queue = queue;
      _rebuildOrder();
      final idx = _queue.indexOf(surah);
      final pos = _playOrder.indexOf(idx);
      _orderPos = pos == -1 ? 0 : pos;
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

  Future<void> playNext() => _advance(1);
  Future<void> playPrevious() => _advance(-1);

  Future<void> _advance(int direction) async {
    if (_playOrder.isEmpty) return;
    var next = _orderPos + direction;
    if (next < 0) next = 0;
    if (next >= _playOrder.length) {
      if (_repeatMode == TilawahRepeatMode.all) {
        next = 0;
      } else {
        return;
      }
    }
    _orderPos = next;
    await playSurah(_queue[_playOrder[_orderPos]]);
  }

  Future<void> _onTrackComplete() async {
    if (_repeatMode == TilawahRepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    await _advance(1);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekRelative(Duration delta) async {
    final newPos = _player.position + delta;
    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _rebuildOrder(keepCurrent: true);
    notifyListeners();
  }

  void cycleRepeatMode() {
    final modes = TilawahRepeatMode.values;
    _repeatMode = modes[(modes.indexOf(_repeatMode) + 1) % modes.length];
    notifyListeners();
  }

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
