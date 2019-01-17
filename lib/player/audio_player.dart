import 'dart:collection';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayer/audioplayer.dart';
import 'dart:async';

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_action_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_action_pause',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/ic_action_stop',
  label: 'Stop',
  action: MediaAction.stop,
);

class CustomAudioPlayer {
  var _queue = Queue<MediaItem>();
  AudioPlayer _audioPlayer = new AudioPlayer();
  Completer _completer = Completer();
  bool _playing = true;
  MediaItem _mediaItem;

  Future<void> run() async {
    var playerStateSubscription = _audioPlayer.onPlayerStateChanged
        .where((state) => state == AudioPlayerState.COMPLETED)
        .listen((state) {
      if (_queue.isEmpty) { 
        stop(); 
      } else {
        play();
      }
    });
    play();
    await _completer.future;
    playerStateSubscription.cancel();
  }

  void add(MediaItem item) {
    _queue.add(item);
  }

  void playPause() {
    if (_playing)
      pause();
    else
      play();
  }

  void play() {
    _mediaItem = _queue.removeFirst();
    AudioServiceBackground.setMediaItem(_mediaItem);
    print(_mediaItem.id);

    const urls = {
      'audio_1': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/De-Aberratio.ogg',
      'audio_2': 'https://upload.wikimedia.org/wikipedia/commons/d/db/De-Galaxie.ogg',
      'audio_3': 'https://upload.wikimedia.org/wikipedia/commons/c/ca/De-Jupiter.ogg',
    };
    var url = urls[_mediaItem.id];
    print(url);

    _audioPlayer.play(url);
    AudioServiceBackground.setState(
      controls: [pauseControl, stopControl],
      basicState: BasicPlaybackState.playing,
    );
  }

  void pause() {
    _audioPlayer.pause();
    AudioServiceBackground.setState(
      controls: [playControl, stopControl],
      basicState: BasicPlaybackState.paused,
    );
  }

  void stop() {
    _audioPlayer.stop();
    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped,
    );
    _completer.complete();
  }
}
