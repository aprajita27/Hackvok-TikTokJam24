import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:example/components/stream_builder_wrapper.dart';
import 'package:example/components/stream_comments.dart';
import 'package:example/models/comments.dart';
import 'package:example/services/post_service.dart';
import 'package:example/view/pages/me/me.dart';
import 'package:example/view/widgets/animation/tiktok_circle_animation.dart';
import 'package:example/utils/firebase/firebase.dart';
import 'package:example/view/widgets/comment_item.dart';
import 'package:example/view/widgets/music_cover.dart';
import 'package:example/view/widgets/user_dp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:example/models/post.dart';
import 'package:example/models/user.dart';
import 'package:example/view/widgets/video/video.dart';

import '../../../services/user_service.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Stream? videoStream;
  UserModel? user;
  bool isLoading=true;

  @override
  void initState() {
    videoStream = postRef.snapshots();
    print("videoStream loaded");
    fetchCurrentUserData();
    super.initState();
  }

  @override
  void dispose() {
    // Stop audio playback when disposing the screen
    // _stopAllAudio();
    super.dispose();
  }

  Future<void> fetchCurrentUserData() async {
    print("in fetching data");
    // currentUserId();
    print("firebase user: ${firebaseAuth.currentUser}");
    UserService userService = UserService();
    print("service initiated");

    UserModel? fetchedUser = await userService.getUserData();
    print("user fetched");
    if (fetchedUser != null) {
      setState(() {
        user = fetchedUser;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print("Failed to fetch user data");
    }
  }

  currentUserId() {

    return firebaseAuth.currentUser!.uid;
  }

  TextEditingController commentTEC = TextEditingController();
  PostService postService = PostService();

  Timestamp timestamp = Timestamp.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : StreamBuilderWrapper(
        stream: videoStream!,
        scrollDirection: Axis.vertical,
        itemBuilder: (_, DocumentSnapshot snapshot) {
          final data = snapshot.data() as Map<String, dynamic>;
          PostModel? video =
              (data.length == 0) ? null : PostModel.fromJson(data);
          //PostModel.fromJson(snapshot.data() as Map<String, dynamic>);
          print(data.length);
          print("user data:${user}");
          return (data.length == 0)
              ? Container(
                  child: Center(child: Text('No Post Found')),
                )
              : Stack(
                  children: [
                    VideoItem(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      videoUrl: video!.mediaUrl, // Video URL
                      originalAudioUrl:
                          video.originalAudioUrl, // Original audio URL
                      selectedAudioUrl: video.selectedAudioUrl,
                      translatedAudioUrls: video.translatedAudioUrl,
                      originalAudioLanguage: video.original_audio_key,
                      knownLanguages: user!.known,
                      preferredLanguage: user!.preferred, // Selected audio URL
                    ),
                    Column(
                      children: [
                        Container(
                          height: 100.0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Following ',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white24,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: CircleAvatar(
                                  radius: 5.0,
                                  backgroundColor: Colors.red,
                                ),
                              ),
                              Container(
                                height: 5.0,
                                width: 1.0,
                                child: VerticalDivider(thickness: 2),
                              ),
                              Text(
                                ' For You',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 70.0,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        '@${video?.username}',
                                        style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        video?.description ?? "flutter tiktok",
                                        style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.music_note, size: 15.0),
                                          Text(
                                            video?.musicName ?? "-",
                                            style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 100.0,
                                margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height /
                                        12),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => Me(
                                              profileId: video.ownerId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: UserDp(userId: video.ownerId),
                                    ),
                                    Column(
                                      children: [
                                        buildLikeButton(video.postId),
                                        SizedBox(height: 5.0),
                                        StreamBuilder(
                                          stream: likeRef
                                              .where('postId',
                                                  isEqualTo: video.postId)
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<QuerySnapshot>
                                                  snapshot) {
                                            if (snapshot.hasData) {
                                              QuerySnapshot snap =
                                                  snapshot.data!;
                                              List<DocumentSnapshot> docs =
                                                  snap.docs;
                                              return buildLikesCount(context,
                                                  docs?.length ?? 0, "likes");
                                            } else {
                                              return buildLikesCount(
                                                  context, 0, "likes");
                                            }
                                          },
                                        ),
                                        InkWell(
                                          onTap: () => buildComment(video),
                                          child: Icon(Icons.comment,
                                              color: Colors.white, size: 40.0),
                                        ),
                                        SizedBox(height: 5.0),
                                        StreamBuilder(
                                          stream: commentRef
                                              .doc(video.postId)
                                              .collection("comments")
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<QuerySnapshot>
                                                  snapshot) {
                                            if (snapshot.hasData) {
                                              QuerySnapshot snap =
                                                  snapshot.data!;
                                              List<DocumentSnapshot> docs =
                                                  snap.docs;
                                              return buildLikesCount(
                                                  context,
                                                  docs?.length ?? 0,
                                                  "comments");
                                            } else {
                                              return buildLikesCount(
                                                  context, 0, "comments");
                                            }
                                          },
                                        ),
                                        GestureDetector(
                                            onTap: () => postService.shareVideo(
                                                video.mediaUrl,
                                                video.postId,
                                                video.id),
                                            child: Icon(Icons.reply,
                                                color: Colors.white,
                                                size: 40.0)),
                                        SizedBox(height: 5.0),
                                        StreamBuilder(
                                          stream: shareRef
                                              .where('postId',
                                                  isEqualTo: video.postId)
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<QuerySnapshot>
                                                  snapshot) {
                                            if (snapshot.hasData) {
                                              QuerySnapshot snap =
                                                  snapshot.data!;
                                              List<DocumentSnapshot> docs =
                                                  snap.docs;
                                              return buildLikesCount(context,
                                                  docs?.length ?? 0, "shares");
                                            } else {
                                              return buildLikesCount(
                                                  context, 0, "shares");
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    TiktokCircleAnimation(
                                      child: MusicCover(),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                );
        },
      ),
    );
  }

  buildLikeButton(String postId) {
    return StreamBuilder(
      stream: likeRef
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: currentUserId())
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> docs = snapshot?.data?.docs ?? [];
          return IconButton(
            onPressed: () {
              if (docs.isEmpty) {
                likeRef.add({
                  'userId': currentUserId(),
                  'postId': postId,
                  'dateCreated': Timestamp.now(),
                });
              } else {
                likeRef.doc(docs[0].id).delete();
              }
            },
            icon: docs.isEmpty
                ? Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 40.0,
                  )
                : Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 40.0,
                  ),
          );
        }
        return Container();
      },
    );
  }

  buildLikesCount(BuildContext context, int count, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 7.0),
      child: Text(
        '$count $text',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  buildComment(PostModel video) {
    return showModalBottomSheet(
      enableDrag: false,
      context: context,
      isDismissible: false,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(25.0),
            topRight: const Radius.circular(25.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 100.0, right: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StreamBuilder(
                    stream: commentRef
                        .doc(video.postId)
                        .collection("comments")
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        QuerySnapshot snap = snapshot.data!;
                        List<DocumentSnapshot> docs = snap.docs;
                        return Text(
                          '${docs?.length.toString() ?? 0.toString()} Comments',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.0,
                              color: Colors.black),
                        );
                      } else {
                        return Text(
                          0.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.0,
                              color: Colors.black),
                        );
                      }
                    },
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.close, size: 20.0, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(child: buildComments(video, video.postId)),
            // Spacer(flex: 5),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: commentTEC,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(10.0),
                          enabledBorder: InputBorder.none,
                          border: InputBorder.none,
                          hintText: "Add Comment...",
                          hintStyle: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                        icon: Icon(
                          Icons.send,
                          size: 20.0,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        onPressed: () {
                          postService.addComments(
                              video, commentTEC.text, timestamp);
                          commentTEC.clear();
                        }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildComments(PostModel video, String postId) {
    return CommentStream(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      scrollDirection: Axis.vertical,
      stream: commentRef
          .doc(video.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      // physics: NeverScrollableScrollPhysics(),
      itemBuilder: (_, DocumentSnapshot snapshot) {
        CommentModel comments =
            CommentModel.fromJson(snapshot.data() as Map<String, dynamic>);
        return CommentItem(comments: comments, postId: postId);
      },
    );
  }
}
