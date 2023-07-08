import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NoteScreen extends StatefulWidget {
  final String lessonId;

  NoteScreen({required this.lessonId});

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  TextEditingController _textEditingController = TextEditingController();
  bool _isEditing = false;
  String _note = '';
  late FlutterTts flutterTts;
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _speechText = '';
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    // Load existing note if available
    _loadNote();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _textEditingController.dispose();
    super.dispose();
  }

  void _loadNote() {
    _firestore.collection('lessons').doc(widget.lessonId).get().then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _note = snapshot.data()!['note'] ?? '';
          _textEditingController.text = _note;
        });
      }
    }).catchError((error) {
      print('Error loading note: $error');
    });
  }

  void _saveNote() {
    final newNote = _textEditingController.text;
    _firestore
        .collection('lessons')
        .doc(widget.lessonId)
        .set({'note': newNote}, SetOptions(merge: true))
        .then((_) {
      setState(() {
        _note = newNote;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note saved successfully')),
      );
    }).catchError((error) {
      print('Error saving note: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note')),
      );
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _textEditingController.text = _note;
      }
    });
  }

  void _speakNote() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.speak(_note);
  }

  void _stopSpeaking() async {
    await flutterTts.stop();
  }

  void _startListening() async {
    if (!_isListening) {
      // Check if microphone permission is granted
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission not granted');
        return;
      }

      // Check if speech recognition is already initialized
      if (!_speechToText.isAvailable) {
        // Initialize speech recognition
        bool available = await _speechToText.initialize(
          onError: (error) => print('Error initializing speech recognition: $error'),
          onStatus: (status) => print('Speech recognition status: $status'),
        );
        if (!available) {
          print('Speech recognition not available');
          return;
        }
      }

      setState(() {
        _isListening = true;
      });

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _speechText = result.recognizedWords;
          });
        },
        listenFor: Duration(minutes: 1),
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      _textEditingController.text += ' ' + _speechText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lesson Note',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _isEditing ? _saveNote : _toggleEdit,
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                ),
                IconButton(
                  onPressed: _isEditing ? () {} : _speakNote,
                  icon: Icon(Icons.volume_up),
                ),
                IconButton(
                  onPressed: _isEditing ? () {} : _stopSpeaking,
                  icon: Icon(Icons.stop),
                ),
              ],
            ),
            SizedBox(height: 8),
            _isEditing
                ? TextField(
                    controller: _textEditingController,
                    autofocus: true,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type your note...',
                      border: OutlineInputBorder(),
                    ),
                  )
                : SingleChildScrollView(
                    child: Text(
                      _note,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
