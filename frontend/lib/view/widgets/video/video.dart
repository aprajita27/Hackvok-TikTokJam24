import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class VideoItem extends StatefulWidget {
  final String videoUrl;
  final String? originalAudioUrl; // Allow originalAudioUrl to be nullable
  final String? selectedAudioUrl; // Allow selectedAudioUrl to be nullable
  final double height;
  final double width;
  final List<String> knownLanguages; // Array of known languages
  final String preferredLanguage;
  final String originalAudioLanguage; // Field for original audio key
  final List<Map<String, String>> translatedAudioUrls;

  const VideoItem(
      {required this.videoUrl,
      this.originalAudioUrl, // Allow originalAudioUrl to be nullable
      this.selectedAudioUrl, // Allow selectedAudioUrl to be nullable
      required this.height,
      required this.width,
      required this.knownLanguages,
      required this.originalAudioLanguage,
      required this.preferredLanguage,
      required this.translatedAudioUrls});

  @override
  _VideoItemState createState() => _VideoItemState();

  // void stopAudio() {
  //   _audioPlayer?.stop();
  // }
}

class _VideoItemState extends State<VideoItem> with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  AudioPlayer? _audioPlayer;
  String? _playingAudioUrl;
  bool _isVideoInitialized = false;
  bool _isAudioInitialized = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _cleanupTempFiles().then((_) {
    //   _initializeVideo();
    //   _handleAudio();
    // });
    _initialize();
  }

  Future<void> _initialize() async {
    await _cleanupTempFiles();
    await _initializeVideo();
    await _handleAudio();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(
      widget.videoUrl,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    await _videoController.initialize();
    _isVideoInitialized = true;
    print("Video initialized: $_isVideoInitialized");
    _loopVideo(); // Add this line
    setState(() {});
    // _videoController = VideoPlayerController.network(
    //   widget.videoUrl,
    //   videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    // )..initialize().then((_) {
    //   _isVideoInitialized = true;
    //   // _checkAndplay();
    //   // _videoController.play();
    //     _videoController.setVolume(0);
    //     _loopVideo(); // Add this line
    //     setState(() {});
    //   });
  }


  Future<void> _handleAudio() async {
    print('Original Audio URL: ${widget.originalAudioUrl}');
    print('Selected Audio URL: ${widget.selectedAudioUrl}');

    if (isValidUrl(widget.originalAudioUrl) &&
        isValidUrl(widget.selectedAudioUrl)) {
      // Check if original audio language is in known languages
      bool isOriginalAudioPreferred =
          widget.knownLanguages.contains(widget.originalAudioLanguage);

      if (isOriginalAudioPreferred) {
        print(
            'Both audio URLs are valid. Using original audio URL: ${widget.originalAudioUrl}');
        await _mixAndPlayAudio(widget.originalAudioUrl!,widget.selectedAudioUrl!);
      } else {
        // Use translated audio for preferred language
        if (widget.translatedAudioUrls.isNotEmpty &&
            widget.translatedAudioUrls[0] is Map) {
          Map<String, String> translatedAudioMap =
              widget.translatedAudioUrls[0] as Map<String, String>;
          String? preferredAudioUrl =
              translatedAudioMap[widget.preferredLanguage];

          if (preferredAudioUrl != null && isValidUrl(preferredAudioUrl)) {
            print(
                'Both audio URLs are valid. Using translated audio for preferred language: $preferredAudioUrl');
            await _mixAndPlayAudio(preferredAudioUrl,widget.selectedAudioUrl!);
          } else {
            print(
                'No valid translated audio URL found for preferred language: ${widget.preferredLanguage}. Using selected audio.');
            await _mixAndPlayAudio(widget.originalAudioUrl!,widget.selectedAudioUrl!);
          }
        } else {
          print(
              'No valid translated audio URLs provided. Using selected audio.');
          await _playSingleAudio(widget.selectedAudioUrl!);
        }
      }
    } else if (isValidUrl(widget.originalAudioUrl)) {
      // Only original audio is valid
      bool isOriginalAudioPreferred =
          widget.knownLanguages.contains(widget.originalAudioLanguage);

      if (isOriginalAudioPreferred) {
        print('Using original audio URL: ${widget.originalAudioUrl}');
        await _playSingleAudio(widget.originalAudioUrl!);
      } else {
        // Use translated audio for preferred language
        if (widget.translatedAudioUrls.isNotEmpty &&
            widget.translatedAudioUrls[0] is Map) {
          Map<String, String> translatedAudioMap =
              widget.translatedAudioUrls[0] as Map<String, String>;
          String? preferredAudioUrl =
              translatedAudioMap[widget.preferredLanguage];

          if (preferredAudioUrl != null && isValidUrl(preferredAudioUrl)) {
            print(
                'Using translated audio for preferred language: $preferredAudioUrl');
            await _playSingleAudio(preferredAudioUrl);
          } else {
            print(
                'No valid translated audio URL found for preferred language: ${widget.preferredLanguage}');
            await _playSingleAudio(widget.originalAudioUrl!);
          }
        } else {
          print('No valid translated audio URLs provided.');
          await _playSingleAudio(widget.originalAudioUrl!);
        }
      }
    } else if (isValidUrl(widget.selectedAudioUrl)) {
      // Only selected audio is valid
      _playingAudioUrl = widget.selectedAudioUrl;
      print('Playing selected audio URL: $_playingAudioUrl');
      await _playSingleAudio(_playingAudioUrl!);
    } else {
      print('No valid audio URLs provided.');
    }
  }

  bool isValidUrl(String? url) {
    if (url == null) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  Future<void> _mixAndPlayAudio(
      String originalAudioUrl, String selectedAudioUrl) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      print('Temporary directory: ${tempDir.path}');

      String mixedAudioUrl = await mixAudioWithBackground(
          originalAudioUrl, selectedAudioUrl, tempDir);
      print('Mixed audio file path: $mixedAudioUrl');

      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.LOOP);
      await _audioPlayer!.setVolume(1.0);
      _setAudioContext();
      _playingAudioUrl = mixedAudioUrl;
      _isAudioInitialized=true;
      _checkAndplay(mixedAudioUrl, isLocal: true);
      // _audioPlayer!.play(mixedAudioUrl, isLocal: true);
      // await _audioPlayer!.setFilePath(mixedAudioUrl);
      // await _audioPlayer!.play();
      // await _audioPlayer!.play(DeviceFileSource(mixedAudioUrl));


    } catch (e) {
      print('Error mixing and playing audio: $e');
    }
  }

  void _loopVideo() {
    _videoController.addListener(() {
      if (_videoController.value.position >= _videoController.value.duration) {
        _videoController.seekTo(Duration.zero);
        _videoController.play();
      }
    });
  }

  Future<void> _playSingleAudio(String audioUrl) async {
    try {
      print('Attempting to play single audio: $audioUrl');
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.LOOP);
      await _audioPlayer!.setVolume(1.0);

      _setAudioContext();
      _isAudioInitialized = true;
      print("audio initialized");
      _checkAndplay(audioUrl);
    } catch (e) {
      print('Error playing single audio: $e');
    }
  }

  void _setAudioContext() {
    if (Platform.isAndroid) {
      _audioPlayer!.setPlaybackRate(1.0); // Example Android setting
      _audioPlayer!.setReleaseMode(ReleaseMode.LOOP); // Example Android setting
      _audioPlayer!.setVolume(1.0); // Example Android setting
    }
  }

  void _checkAndplay(String audioUrl, {bool isLocal = false}) async {
    print("in check and play");
    print("initializations:${_isVideoInitialized},${_isAudioInitialized}");
    if (_isVideoInitialized && _isAudioInitialized) {
      print("both initialized");
      _audioPlayer!.play(audioUrl, isLocal: isLocal);
      await Future.delayed(Duration(milliseconds: 1900));
      _videoController.play();
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.removeListener(_loopVideo);
    _videoController.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _cleanupTempFiles();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopAndDisposeAudioPlayer();
    }
  }

  void _stopAndDisposeAudioPlayer() {
    if (_audioPlayer != null) {
      _audioPlayer!.stop();
      _audioPlayer!.dispose();
      _audioPlayer = null;
    }
  }


  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _audioPlayer!.setVolume(_isMuted ? 0.0 : 1.0); // Toggle volume
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.5),
          bottomRight: Radius.circular(6.5),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isVideoInitialized // Check if video is initialized before using VideoPlayer
              ? VideoPlayer(_videoController)
              : Center(child: CircularProgressIndicator()),
        ],
      ),
    )
    );
  }
}

Future<String> mixAudioWithBackground(
    String originalAudioUrl, String selectedAudioUrl, Directory tempDir) async {
  try {
    String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    print('Downloading original audio from: $originalAudioUrl');
    Uint8List originalAudioBytes = await downloadAudioBytes(originalAudioUrl);
    print('Downloading selected audio from: $selectedAudioUrl');
    Uint8List selectedAudioBytes = await downloadAudioBytes(selectedAudioUrl);

    final originalAudioPath = '${tempDir.path}/original_audio_$uniqueId.mp3';
    final selectedAudioPath = '${tempDir.path}/selected_audio_$uniqueId.mp3';
    print('Writing original audio to: $originalAudioPath');
    await File(originalAudioPath).writeAsBytes(originalAudioBytes);
    print('Writing selected audio to: $selectedAudioPath');
    await File(selectedAudioPath).writeAsBytes(selectedAudioBytes);

    final mixedAudioPath = '${tempDir.path}/mixed_audio_$uniqueId.mp3';
    print('Mixed audio will be saved to: $mixedAudioPath');

    String ffmpegCommand =
        '-i $originalAudioPath -i $selectedAudioPath -filter_complex "[0:a]volume=3.0[a0];[1:a]volume=0.2[a1];[a0][a1]amix=inputs=2:duration=first:dropout_transition=2[a]" -map "[a]" -c:a aac -b:a 192k -f mp4 -y $mixedAudioPath';
    print('Executing FFmpeg command: $ffmpegCommand');
    await FFmpegKit.execute(ffmpegCommand);

    File mixedAudioFile = File(mixedAudioPath);
    if (await mixedAudioFile.exists()) {
      print('Mixed audio file created successfully');
    } else {
      print('Mixed audio file does not exist');
      throw Exception('Mixed audio file does not exist: $mixedAudioPath');
    }

    // Clean up individual audio files
    await File(originalAudioPath).delete();
    await File(selectedAudioPath).delete();

    return mixedAudioPath;
  } catch (e) {
    print('Error mixing audio: $e');
    rethrow;
  }
}

Future<Uint8List> downloadAudioBytes(String audioUrl) async {
  try {
    print('Attempting to download audio from: $audioUrl');
    final http.Response response = await http.get(Uri.parse(audioUrl));
    if (response.statusCode == 200) {
      print('Audio downloaded successfully');
      return response.bodyBytes;
    } else {
      print('Failed to download audio. Status code: ${response.statusCode}');
      throw Exception('Failed to download audio: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading audio: $e');
    rethrow;
  }
}

Future<void> _cleanupTempFiles() async {
  try {
    Directory tempDir = await getTemporaryDirectory();
    List<String> filesToDelete = [
      'original_audio.mp3',
      'selected_audio.mp3',
      'mixed_audio.mp3'
    ];

    for (String fileName in filesToDelete) {
      File file = File('${tempDir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
        print('Deleted temporary file: ${file.path}');
      }
    }
  } catch (e) {
    print('Error cleaning up temporary files: $e');
  }
}
