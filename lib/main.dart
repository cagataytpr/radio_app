import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'views/radio_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.bozukradyo.channel.audio',
    androidNotificationChannelName: 'Radio Playback',
    androidNotificationOngoing: true,
  );
  runApp(const BozukRadyoApp());
}

class BozukRadyoApp extends StatelessWidget {
  const BozukRadyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bozuk Radyo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const RadioHomePage(),
    );
  }
}