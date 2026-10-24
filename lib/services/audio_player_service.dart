import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Surah? _currentSurah;
  List<Surah> _queue = [];
  int _queueIndex = 0;

  Surah? get currentSurah => _currentSurah;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get totalDuration => _player.duration;
  Stream<Duration> get positionStream => _player.positionStream;

  AudioPlayerService() {
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> playSurah(Surah surah, String audioUrl,
      {List<Surah>? queue}) async {
    _currentSurah = surah;
    if (queue != null) {
      _queue = queue;
      _queueIndex = queue.indexWhere((s) => s.number == surah.number);
    }
    await _player.setUrl(audioUrl);
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
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty || _queueIndex <= 0) return;
    _queueIndex--;
  }

  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
