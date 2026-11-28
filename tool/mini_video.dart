// Minimal media_kit sanity check: same dependencies, no app shell.
// Run: flutter build windows --debug -t tool/mini_video.dart
//      SP_TEST_MEDIA=<file> sp_player.exe
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MiniApp());
}

class MiniApp extends StatefulWidget {
  const MiniApp({super.key});

  @override
  State<MiniApp> createState() => _MiniAppState();
}

class _MiniAppState extends State<MiniApp> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: Platform.environment['SP_CFG'] == 'fixed'
        ? const VideoControllerConfiguration(
            width: 1920,
            height: 1080,
            hwdec: 'auto-safe',
            enableHardwareAcceleration: true,
          )
        : const VideoControllerConfiguration(),
  );

  @override
  void initState() {
    super.initState();
    final path = Platform.environment['SP_TEST_MEDIA'] ?? '';
    if (path.isNotEmpty) {
      player.open(Media(path));
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(child: Video(controller: controller)),
            StreamBuilder<Duration>(
              stream: player.stream.position,
              builder: (context, snap) => Text(
                'pos=${snap.data ?? Duration.zero} '
                'id=${controller.id.value} rect=${controller.rect.value}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
