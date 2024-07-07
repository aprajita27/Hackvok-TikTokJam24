import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicSelectionScreen extends StatefulWidget {
  @override
  _MusicSelectionScreenState createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  List<dynamic> musicList = [];

  @override
  void initState() {
    super.initState();
    fetchMusic();
  }

  Future<void> fetchMusic() async {
    final response = await http.get(Uri.parse('https://api.deezer.com/search?q=top&limit=10'));
    if (response.statusCode == 200) {
      setState(() {
        musicList = json.decode(response.body)['data'];
      });
    } else {
      throw Exception('Failed to load music');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Music'),
      ),
      body: musicList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: musicList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(musicList[index]['title']),
            subtitle: Text(musicList[index]['artist']['name']),
            onTap: () {
              Navigator.pop(context, {
                'name': musicList[index]['title'],
                'artist': musicList[index]['artist']['name'],
                'url': musicList[index]['preview']
              });
            },
          );
        },
      ),
    );
  }
}
