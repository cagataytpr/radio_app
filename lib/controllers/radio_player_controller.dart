import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../models/radio_model.dart';

class RadioPlayerController extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();

  final List<RadioModel> channels = const [
    RadioModel(name: 'Radyo 1', url: 'http://radyoserver.qbilisim.com:8114/;'),
    RadioModel(name: 'Radyo 2', url: 'http://radyoserver.qbilisim.com:7016/;'),
  ];

  RadioModel? currentChannel;
  bool isLoading = false;
  String? errorMessage;

  RadioPlayerController() {
    WidgetsBinding.instance.addObserver(this);
    _initAudioSession();
    _player.setVolume(1.0); // Ensure maximum volume starts at 100%
    _player.playerStateStream.listen((state) {
      notifyListeners();
    });
    _player.volumeStream.listen((vol) {
      notifyListeners();
    });
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop playback if the app is being completely closed (task removed)
    if (state == AppLifecycleState.detached) {
      _player.stop();
    }
  }

  bool get isPlaying => _player.playing;
  
  bool get isBuffering =>
      _player.processingState == ProcessingState.buffering ||
      _player.processingState == ProcessingState.loading;
      
  double get volume => _player.volume;

  Future<void> playChannel(RadioModel channel) async {
    if (currentChannel?.url == channel.url) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    currentChannel = channel;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _player.stop();
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(channel.url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Icy-MetaData': '1',
          },
          tag: MediaItem(
            id: channel.url,
            album: 'Bozuk Radyo',
            title: channel.name,
            artist: 'Canlı Yayın',
            artUri: Uri.parse('https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/User_icon_2.svg/2048px-User_icon_2.svg.png'), // Replace with actual logo if needed
          ),
        ),
      );
      await _player.play();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') ||
          errorStr.contains('400') ||
          errorStr.contains('unknownhostexception') ||
          errorStr.contains('failed to connect') ||
          errorStr.contains('socketexception')) {
        errorMessage = 'Kanal şu an çevrimdışı';
      } else {
        errorMessage = 'Bağlantı Hatası: Lütfen internetinizi kontrol edin.\n$e';
      }
      currentChannel = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setVolume(double value) {
    _player.setVolume(value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }
}
