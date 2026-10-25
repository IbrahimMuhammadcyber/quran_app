import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/surah.dart';
import 'audio_handler.dart';
import 'storage_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final TilawahAudioHandler handler;
  final StorageService storage = StorageService();

  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;
  Timer? _positionSaveTimer;

  AudioPlayerService(this.handler) {
    handler.playbackState.listen((_) => notifyListeners());
    handler.mediaItem.listen((_) => notifyListeners());
    _positionSaveTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => handler.saveProgress());
  }

  Surah? get currentSurah => handler.currentSurah;
  bool get isPlaying => handler.player.playing;
  Duration get position => handler.player.position;
  Duration? get totalDuration => handler.player.duration;
  Stream<Duration> get positionStream => handler.player.positionStream;
  String get reciter => handler.reciter;
  Duration? get sleepTimerDuration => _sleepTimerDuration;
  TilawahRepeatMode get repeatMode => handler.repeatMode;
  bool get shuffleEnabled => handler.shuffleEnabled;

  void setReciter(String reciterId) {
    handler.setReciter(reciterId);
    notifyListeners();
  }

  Future<void> playSurah(Surah surah,
      {List<Surah>? queue, Duration? startAt}) async {
    await handler.playSurahNow(surah, queue ?? [surah], startAt: startAt);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (handler.player.playing) {
      await handler.pause();
    } else {
      await handler.play();
    }
  }

  Future<void> playNext() => handler.skipToNext();
  Future<void> playPrevious() => handler.skipToPrevious();
  Future<void> seek(Duration position) => handler.seek(position);
  Future<void> seekRelative(Duration delta) => handler.seekRelative(delta);

  void toggleShuffle() {
    handler.toggleShuffle();
    notifyListeners();
  }

  void cycleRepeatMode() {
    final modes = TilawahRepeatMode.values;
    final next =
        modes[(modes.indexOf(handler.repeatMode) + 1) % modes.length];
    handler.setLoopMode(next);
    notifyListeners();
  }

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    _sleepTimer = Timer(duration, () {
      handler.pause();
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
      handler.api.audioUrlFor(surahNumber, reciter: handler.reciter);

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSaveTimer?.cancel();
    super.dispose();
  }
}
