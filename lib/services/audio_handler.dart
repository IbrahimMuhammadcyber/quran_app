import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import 'quran_api_service.dart';
import 'storage_service.dart';

enum RepeatMode { off, all, one }

class TilawahAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  final QuranApiService api = QuranApiService();
  final StorageService storage = StorageService();

  List<Surah> _surahQueue = [];
  List<int> _playOrder = [];
  int _orderPos = 0;
  String _reciter = 'ar.alafasy';
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffle = false;

  Surah? get currentSurah =>
      _surahQueue.isNotEmpty && _orderPos < _playOrder.length
          ? _surahQueue[_playOrder[_orderPos]]
          : null;
  String get reciter => _reciter;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffle;

  TilawahAudioHandler() {
    player.playbackEventStream.listen(_broadcastState);
    player.durationStream.listen((d) {
      final item = mediaItem.value;
      if (item != null && d != null) {
        mediaItem.add(item.copyWith(duration: d));
      }
    });
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackComplete();
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: _orderPos,
    ));
  }

  void setReciter(String reciterId) {
    _reciter = reciterId;
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _rebuildOrder(keepCurrent: true);
  }

  void _rebuildOrder({bool keepCurrent = false}) {
    final current = currentSurah;
    final currentIndex = current != null ? _surahQueue.indexOf(current) : -1;
    final indices = List<int>.generate(_surahQueue.length, (i) => i);
    if (_shuffle) indices.shuffle();
    _playOrder = indices;
    if (keepCurrent && currentIndex != -1) {
      final pos = _playOrder.indexOf(currentIndex);
      _orderPos = pos == -1 ? 0 : pos;
    } else {
      _orderPos = 0;
    }
  }

  Future<void> _loadCurrent({Duration? startAt}) async {
    final surah = currentSurah;
    if (surah == null) return;

    mediaItem.add(MediaItem(
      id: surah.number.toString(),
      title: '${surah.number} - ${surah.nameTransliteration}',
      artist: _reciter,
    ));

    final localPath =
        await storage.localPathIfDownloaded(_reciter, surah.number);
    if (localPath != null) {
      await player.setFilePath(localPath);
    } else {
      await player.setUrl(api.audioUrlFor(surah.number, reciter: _reciter));
    }
    if (startAt != null) await player.seek(startAt);
  }

  Future<void> playSurahNow(Surah surah, List<Surah> queue,
      {Duration? startAt}) async {
    _surahQueue = queue;
    _rebuildOrder();
    final startIndex = _surahQueue.indexOf(surah);
    final pos = _playOrder.indexOf(startIndex);
    _orderPos = pos == -1 ? 0 : pos;
    await _loadCurrent(startAt: startAt);
    await play();
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  Future<void> seekRelative(Duration delta) async {
    final newPos = player.position + delta;
    await player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  @override
  Future<void> skipToNext() => _advance(1);

  @override
  Future<void> skipToPrevious() => _advance(-1);

  Future<void> _advance(int direction) async {
    if (_playOrder.isEmpty) return;
    var next = _orderPos + direction;
    if (next < 0) next = 0;
    if (next >= _playOrder.length) {
      if (_repeatMode == RepeatMode.all) {
        next = 0;
      } else {
        return;
      }
    }
    _orderPos = next;
    await _loadCurrent();
    await player.play();
  }

  Future<void> _onTrackComplete() async {
    if (_repeatMode == RepeatMode.one) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    await _advance(1);
  }

  @override
  Future<void> stop() async {
    await player.stop();
    return super.stop();
  }

  Future<void> saveProgress() async {
    final surah = currentSurah;
    if (surah != null) {
      await storage.saveLastPlayed(
        surahNumber: surah.number,
        reciter: _reciter,
        positionMs: player.position.inMilliseconds,
      );
    }
  }
}
