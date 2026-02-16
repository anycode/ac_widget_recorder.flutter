import 'package:flutter/widgets.dart';
import 'package:flutter_widget_recorder/src/recording_controller.dart';

class WidgetRecorder extends StatefulWidget {
  final Widget child;
  final RecordingController controller;

  const WidgetRecorder({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<WidgetRecorder> createState() => _WidgetRecorderState();
}

class _WidgetRecorderState extends State<WidgetRecorder> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller.repaintBoundaryKey,
      child: widget.child,
    );
  }
}