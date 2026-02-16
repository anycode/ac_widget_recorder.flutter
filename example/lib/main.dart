import 'package:flutter/material.dart';
import 'package:flutter_widget_recorder/flutter_widget_recorder.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory, getDownloadsDirectory;
import 'package:uuid/uuid.dart' show Uuid;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: RecorderExample());
  }
}

class RecorderExample extends StatefulWidget {
  const RecorderExample({super.key});

  @override
  State<RecorderExample> createState() => _RecorderExampleState();
}

class _RecorderExampleState extends State<RecorderExample> {
  bool isPathLoaded = false;
  String videoExportPath = '';
  late RecordingController recorderController;
  int frameCount = 0;

  loadVideoExportPathAndInitController() async {
    final tempDirectory = await getTemporaryDirectory();
    videoExportPath = '${tempDirectory.path}/${Uuid().v4()}.mp4';
    recorderController = RecordingController(fps: 8, updateFrameCount: (count) => setState(() => frameCount = count), showLogs: true);
    setState(() {
      isPathLoaded = true;
    });
  }

  @override
  void initState() {
    loadVideoExportPathAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Recorder Demo')),
      body: isPathLoaded
          ? WidgetRecorder(
              controller: recorderController,
              child: Container(
                decoration: recorderController.isRecording
                    ? BoxDecoration(
                        border: Border.all(color: Colors.red, width: 4),
                        color: Colors.green,
                      )
                    : null,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text("Recording Test! $frameCount frames recorded", style: Theme.of(context).textTheme.headlineMedium),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await recorderController.startRecording(exportPath: '${(await getDownloadsDirectory())!.path}/test.mp4');
                            setState(() {});
                          },
                          child: const Text("Start"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await recorderController.stopRecording();
                            setState(() {});
                          },
                          child: const Text("Stop"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
