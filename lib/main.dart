import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:ltp/player/audio_player.dart';

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
                ? [addButton(), pauseButton(), stopButton()]
                : _state?.basicState == BasicPlaybackState.paused
                    ? [addButton(), playButton(), stopButton()]
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

  IconButton addButton() => IconButton(
        icon: Icon(Icons.add_to_queue),
        iconSize: 64.0,
        onPressed: () {
          MediaItem item = MediaItem(
            id: 'audio_1',
            album: 'Sample Album',
            title: 'Sample Title',
            artist: 'Sample Artist');
          AudioService.addQueueItem(item);
        }
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
  // todo: check queue is not empty
  // todo: if queue is empty do not start service
  CustomAudioPlayer player = CustomAudioPlayer();
  
  for (int i = 1; i <= 3; i++) {
    player.add(MediaItem(
            id: 'audio_' + i.toString(),
            album: 'Bhagavad-gita',
            title: 'BG 01.01',
            artist: 'A. C. Bhaktivedanta Swami Prabhupada',
            artUri: 'https://24hourkirtan.fm/wp-content/uploads/2015/02/srila-prabhupada-e1423317264773.jpg'));
  }

  AudioServiceBackground.run(
    onStart: player.run,
    onPlay: player.play,
    onAddQueueItem: player.add,
    onPause: player.pause,
    onStop: player.stop,
    onClick: (MediaButton button) => player.playPause(),
  );
}
