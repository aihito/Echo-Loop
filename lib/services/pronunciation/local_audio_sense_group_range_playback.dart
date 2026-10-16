import '../../database/daos/audio_item_dao.dart';
import '../../models/sense_group_range_playback.dart';
import 'local_audio_clip_player.dart';
import 'local_audio_range_player.dart';

/// 使用共享短音频播放器执行句子复习中的意群区间试听。
class LocalAudioSenseGroupRangePlayback implements SenseGroupRangePlayback {
  LocalAudioSenseGroupRangePlayback({
    required AudioItemDao audioItemDao,
    required LocalAudioClipPlayer audioClipPlayer,
  }) : _audioClipPlayer = audioClipPlayer,
       _rangePlayer = LocalAudioRangePlayer(
         audioItemDao: audioItemDao,
         audioClipPlayer: audioClipPlayer,
       );

  final LocalAudioClipPlayer _audioClipPlayer;
  final LocalAudioRangePlayer _rangePlayer;

  @override
  Future<void> play(String audioItemId, Duration start, Duration end) async {
    await _rangePlayer.play(
      audioItemId: audioItemId,
      start: start,
      end: end,
      playbackKey:
          'favorite-sentence-review-sense-group:$audioItemId:'
          '${start.inMilliseconds}:${end.inMilliseconds}',
    );
  }

  @override
  Future<void> cancel() => _audioClipPlayer.stop();
}
