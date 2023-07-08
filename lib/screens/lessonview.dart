import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tutorapp/screens/notes.dart';

class LessonViewScreen extends StatefulWidget {
  final String lessonId;

  LessonViewScreen(this.lessonId);

  @override
  _LessonViewScreenState createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void speakLessonContent(String content) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.speak(content);
  }

  void stopSpeaking() async {
    await flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson View'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('lessons').doc(widget.lessonId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lessonData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  lessonData['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          lessonData['content'],
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Go to previous lesson
                      },
                      icon: Icon(Icons.arrow_back),
                      color: Colors.blue,
                      splashRadius: 24.0,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (isSpeaking) {
                              stopSpeaking();
                            } else {
                              speakLessonContent(lessonData['content']);
                            }
                            setState(() {
                              isSpeaking = !isSpeaking;
                            });
                          },
                          icon: Icon(Icons.volume_up),
                          color: Colors.blue,
                          splashRadius: 24.0,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            stopSpeaking();
                            setState(() {
                              isSpeaking = false;
                            });
                          },
                          icon: Icon(Icons.stop),
                          color: Colors.blue,
                          splashRadius: 24.0,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        // Go to next lesson
                      },
                      icon: Icon(Icons.arrow_forward),
                      color: Colors.blue,
                      splashRadius: 24.0,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        setState(() {
                          isCompleted = value ?? false;
                        });
                      },
                    ),
                    Text('Mark as Complete'),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteScreen(lessonId: widget.lessonId),
                          ),
                        );
                      },
                      child: Text('Add Notes'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
