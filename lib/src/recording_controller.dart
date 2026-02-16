import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart';

class RecordingController {
  String? _pipe; // Path returned by ffmpeg-kit
  IOSink? _pipeSink; // Writable sink for frames
  Timer? _recordingTimer;

  ReturnCode? returnCode;

  final GlobalKey repaintBoundaryKey = GlobalKey();

  bool _isRecording = false;

  bool get isRecording => _isRecording;

  int _frameCount = 0;
  int _width = 0;
  int _height = 0;
  String _videoExportPath = '';

  /// Callback function called when recording starts. Function is called with
  /// String argument which is the path where the video will be exported.
  final ValueChanged<String>? onStarted;
  
  /// Callback function called when recording ends. Function is called with
  /// String argument which is the path where the video was exported.
  final ValueChanged<String>? onStopped;
  
  /// Callback function called when frame count changes. Function is called with
  /// int argument which is the current frame count.
  final ValueChanged<int>? updateFrameCount;
  
  /// Required frames per second, defaults to 10.
  final int fps;
  
  /// Flag determining whether logs should be printed. Defaults to false.
  final bool showLogs;

  /// Creates a [RecordingController] for recording widget frames to video.
  ///
  /// [onStarted] - Optional callback invoked when recording begins successfully.
  /// Receives the export path as an argument.
  ///
  /// [onStopped] - Optional callback invoked when recording ends.
  /// Receives the export path as an argument.
  ///
  /// [fps] - Frames per second for video recording. Defaults to 10.
  ///
  /// [updateFrameCount] - Optional callback invoked each time a frame is captured.
  /// Receives the current frame count as an argument.
  ///
  /// [showLogs] - Whether to print debug logs during recording. Defaults to false.
  RecordingController({this.onStarted, this.onStopped, this.fps = 10, this.updateFrameCount, this.showLogs = false});

  /// Start recording.
  ///
  /// Sets up ffmpeg pipe and begins pushing frames at the specified [fps].
  ///
  /// [exportPath] - Optional path where the video will be saved. If not provided,
  /// a temporary directory will be used with a timestamp-based filename.
  ///
  /// Returns the export path if recording started successfully, or `null` if
  /// recording is already in progress or if the RenderRepaintBoundary is not found.
  Future<String?> startRecording({String? exportPath}) async {
    if (_isRecording) return null;

    _isRecording = true;
    _frameCount = 0;

    // Wait until first frame is fully painted
    await WidgetsBinding.instance.endOfFrame;

    final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      developer.log('❌ No RenderRepaintBoundary found');
      return null;
    }

    _videoExportPath = exportPath ?? '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
    developer.log('   Export path: $_videoExportPath');

    final image = await boundary.toImage(pixelRatio: 2.0);
    _width = image.width;
    _height = image.height;

    // Create ffmpeg pipe
    _pipe = await FFmpegKitConfig.registerNewFFmpegPipe();
    _pipeSink = File(_pipe!).openWrite();

    // ffmpeg command
    final command = [
      '-y',
      '-f',
      'rawvideo',
      '-pix_fmt',
      'rgba',
      '-s',
      '${_width}x$_height',
      '-r',
      fps.toString(),
      '-i',
      _pipe!,
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      _videoExportPath,
    ].join(' ');

    // Run ffmpeg in background
    FFmpegKit.executeAsync(command, (session) async {
      returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        developer.log("✅ Video created at $_videoExportPath");
      } else {
        developer.log("❌ FFmpeg failed with code: $returnCode");
      }
    });

    // Capture frames periodically
    final interval = Duration(milliseconds: 1000 ~/ fps);
    _recordingTimer = Timer.periodic(interval, (_) => _captureFrame());

    developer.log("🎥 Recording started with size: $_width x $_height");

    onStarted?.call(_videoExportPath);
    return _videoExportPath;
  }

  /// Stop recording and finalize the video.
  ///
  /// Stops capturing frames, flushes and closes the ffmpeg pipe, and waits for
  /// the video encoding to complete.
  ///
  /// Returns the export path where the video was saved if recording was active,
  /// or `null` if no recording was in progress.
  ///
  /// The [onStopped] callback will be invoked with the export path when recording
  /// stops successfully.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    _recordingTimer?.cancel();

    await _pipeSink?.flush();
    await _pipeSink?.close();

    _pipe = null;
    _pipeSink = null;
    _frameCount = 0;

    developer.log("🎬 Recording stopped");

    onStopped?.call(_videoExportPath);
    return _videoExportPath;
  }

  /// Cancel recording without saving the video.
  ///
  /// Stops capturing frames and closes the ffmpeg pipe without finalizing the video.
  /// Unlike [stopRecording], this method does not wait for video encoding to complete
  /// and the video file will not be created.
  ///
  /// Does nothing if no recording is in progress.
  ///
  /// This is useful when you want to discard the recording without creating a video file.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _recordingTimer?.cancel();

    await _pipeSink?.close();

    _pipe = null;
    _pipeSink = null;
    _frameCount = 0;

    developer.log("🛑 Recording canceled");
  }

  /// Internal: capture a single frame and push to ffmpeg pipe
  Future<void> _captureFrame() async {
    if (!_isRecording || _pipeSink == null) return;

    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      // pipe closed meanwhile
      if(_pipeSink == null) return;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      // no data or pipe closed meanwhile
      if (byteData == null || _pipeSink == null) return;

      _pipeSink!.add(byteData.buffer.asUint8List());
      _frameCount++;

      updateFrameCount?.call(_frameCount);
      if (showLogs) developer.log("✅ Frame $_frameCount pushed");
    } catch (e) {
      developer.log("⚠️ Error capturing frame: $e");
    }
  }
}
