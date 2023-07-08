import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tutorapp/screens/lessonview.dart';

class LessonSelectionScreen extends StatelessWidget {
  final String courseId;

  LessonSelectionScreen(this.courseId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson Selection'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').doc(courseId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final courseData = snapshot.data!.data() as Map<String, dynamic>;
          final lessons = courseData['lessons'] as List<dynamic>;

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lessonRef = lessons[index];
              final lessonId = lessonRef; // Use the lessonRef as the lesson ID

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('lessons').doc(lessonId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  final lessonData = snapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(lessonData['title']),
                    subtitle: Text(lessonData['description']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonViewScreen(lessonId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
