import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:audio_service/audio_service.dart';

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

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  PlaybackState _state;
  StreamSubscription _playbackStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    connect();
  }

  @override
  void dispose() {
    disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        connect();
        break;
      case AppLifecycleState.paused:
        disconnect();
        break;
      default:
        break;
    }
  }

  void connect() async {
    await AudioService.connect();
    if (_playbackStateSubscription == null) {
      _playbackStateSubscription = AudioService.playbackStateStream
          .listen((PlaybackState playbackState) {
        setState(() {
          _state = playbackState;
        });
      });
    }
  }

  void disconnect() {
    if (_playbackStateSubscription != null) {
      _playbackStateSubscription.cancel();
      _playbackStateSubscription = null;
    }
    AudioService.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Audio Service Demo'),
        ),
        body: new Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _state?.basicState == BasicPlaybackState.playing
                ? [pauseButton(), stopButton()]
                : _state?.basicState == BasicPlaybackState.paused
                    ? [playButton(), stopButton()]
                    : [audioPlayerButton()],
          ),
        ),
      ),
    );
  }

  RaisedButton audioPlayerButton() =>
      startButton('AudioPlayer', _backgroundAudioPlayerTask);

  RaisedButton startButton(String label, Function backgroundTask) =>
      RaisedButton(
        child: Text(label),
        onPressed: () {
          AudioService.start(
            backgroundTask: backgroundTask,
            resumeOnClick: true,
            androidNotificationChannelName: 'Listen To Prabhupada',
            androidNotificationIcon: 'mipmap/ic_launcher'
          );
        },
      );

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 64.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 64.0,
        onPressed: AudioService.pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: 64.0,
        onPressed: AudioService.stop,
      );
}

void _backgroundAudioPlayerTask() async {
  CustomAudioPlayer player = CustomAudioPlayer();
  AudioServiceBackground.run(
    onStart: player.run,
    onPlay: player.play,
    onPause: player.pause,
    onStop: player.stop,
    onClick: (MediaButton button) => player.playPause(),
  );
}

class CustomAudioPlayer {
  static const streamUri =
      'http://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
  AudioPlayer _audioPlayer = new AudioPlayer();
  Completer _completer = Completer();
  bool _playing = true;

  Future<void> run() async {
    MediaItem mediaItem = MediaItem(
        id: 'audio_1',
        album: 'Sample Album',
        title: 'Sample Title',
        artist: 'Sample Artist');

    AudioServiceBackground.setMediaItem(mediaItem);

    var playerStateSubscription = _audioPlayer.onPlayerStateChanged
        .where((state) => state == AudioPlayerState.COMPLETED)
        .listen((state) {
      stop();
    });
    play();
    await _completer.future;
    playerStateSubscription.cancel();
  }

  void playPause() {
    if (_playing)
      pause();
    else
      play();
  }

  void play() {
    _audioPlayer.play(streamUri);
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
