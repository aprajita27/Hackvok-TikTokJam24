import 'dart:io';

import 'package:flutter/material.dart';
import 'package:example/view_model/post/create_post_view_model.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:example/view/screens/music_selection_screen.dart';
import 'package:example/utils/audio_options.dart';

class CreatePost extends StatefulWidget {
  final File vid;
  final VoidCallback navigateToMePage; // Ensure this is correctly defined

  const CreatePost({Key? key, required this.vid, required this.navigateToMePage}) : super(key: key);

  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  VideoPlayerController? controller;
  AudioOption _audioOption = AudioOption.original;
  bool _isAudioOff = true; // Initial state for audio off

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(widget.vid)
      ..initialize().then((_) {
        setState(() {});
        controller!.play();
        controller!.setVolume(0.5);
        controller!.setLooping(true);
      });
  }

  @override
  void dispose() {
    controller?.dispose(); // Dispose the controller when the widget is disposed
    super.dispose();
  }

  void _toggleAudioOff(PostsViewModel viewModel) {
    setState(() {
      _isAudioOff = !_isAudioOff;
      _updateAudioOption(viewModel); // Update audio option based on new state
    });
  }

  void _updateAudioOption(PostsViewModel viewModel) {
    if (_isAudioOff && viewModel.musicUrl.isEmpty) {
      // Scenario 1: No audio when audio is off and no music is selected
      setState(() {
        _audioOption = AudioOption.none;
      });
    } else if (_isAudioOff && viewModel.musicUrl.isNotEmpty) {
      // Scenario 2: Selected music when audio is off but music is selected
      setState(() {
        _audioOption = AudioOption.selected;
      });
    } else if (!_isAudioOff && viewModel.musicUrl.isNotEmpty) {
      // Scenario 3: Both when audio is on and music is selected
      setState(() {
        _audioOption = AudioOption.both;
      });
    } else if (!_isAudioOff && viewModel.musicUrl.isEmpty) {
      // Scenario 4: Original when audio is on and no music is selected
      setState(() {
        _audioOption = AudioOption.original;
      });
    }
    viewModel.setAudioOption(_audioOption); // Notify view model of the selected option
  }

  @override
  Widget build(BuildContext context) {
    PostsViewModel viewModel = Provider.of<PostsViewModel>(context);

    return ModalProgressHUD(
      inAsyncCall: viewModel.loading,
      progressIndicator: CircularProgressIndicator(),
      child: Scaffold(
        key: viewModel.scaffoldMessengerKey,
        appBar: AppBar(
          leading: InkWell(
            onTap: () async {
              await viewModel.resetPost();
              Navigator.pop(context);
            },
            child: Icon(Icons.keyboard_backspace),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: InkWell(
                onTap: () async {
                  await viewModel.handleUpload(context, widget.navigateToMePage);
                },
                child: Text(
                  'Upload',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller!.value.isInitialized)
                  Container(
                    height: MediaQuery.of(context).size.height / 1.5,
                    width: MediaQuery.of(context).size.width,
                    child: VideoPlayer(controller!),
                  ),
                SizedBox(height: 20.0),
                Text(
                  'Song Name'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        viewModel.musicName?.isNotEmpty == true
                            ? '${viewModel.musicName} | ${viewModel.artistName}'
                            : 'No music selected',
                        style: TextStyle(fontSize: 15.0),
                      ),
                    ),
                    IconButton(
                      icon: _isAudioOff
                          ? Icon(Icons.volume_off) // Audio off icon
                          : Icon(Icons.volume_up), // Audio on icon
                      onPressed: () {
                        _toggleAudioOff(viewModel); // Toggle audio off/on
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.library_music),
                      onPressed: () async {
                        var music = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusicSelectionScreen(),
                          ),
                        );
                        if (music != null) {
                          viewModel.setMusicName(music['name']);
                          viewModel.setArtistName(music['artist']);
                          viewModel.setMusicUrl(music['url']); // Set the music URL
                          _updateAudioOption(viewModel); // Update audio option when music changes
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.0),
                Text(
                  'Caption'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextFormField(
                  initialValue: viewModel.description,
                  decoration: InputDecoration(
                    hintText: 'Eg. Awesome Video!!',
                    focusedBorder: UnderlineInputBorder(),
                  ),
                  maxLines: null,
                  onChanged: (val) => viewModel.setDescription(val),
                ),
                SizedBox(height: 20.0),
                Text(
                  'Audio Option'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<AudioOption>(
                      title: Text('Original audio'),
                      value: AudioOption.original,
                      groupValue: _audioOption,
                      onChanged: (value) {
                        setState(() {
                          _audioOption = value!;
                          viewModel.setAudioOption(value);
                        });
                      },
                    ),
                    RadioListTile<AudioOption>(
                      title: Text('Selected music'),
                      value: AudioOption.selected,
                      groupValue: _audioOption,
                      onChanged: (value) {
                        setState(() {
                          _audioOption = value!;
                          viewModel.setAudioOption(value);
                        });
                      },
                    ),
                    RadioListTile<AudioOption>(
                      title: Text('Both original and selected music'),
                      value: AudioOption.both,
                      groupValue: _audioOption,
                      onChanged: (value) {
                        setState(() {
                          _audioOption = value!;
                          viewModel.setAudioOption(value);
                        });
                      },
                    ),
                    RadioListTile<AudioOption>(
                      title: Text('No audio'),
                      value: AudioOption.none,
                      groupValue: _audioOption,
                      onChanged: (value) {
                        setState(() {
                          _audioOption = value!;
                          viewModel.setAudioOption(value);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

