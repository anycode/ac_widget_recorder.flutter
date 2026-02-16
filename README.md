````markdown
# ac_widget_recorder

A Flutter plugin to capture widget as a video and save it locally.
Based on and inspired by `https://github.com/J-Libraries/flutter_screen_capture.git`

> ✅ Records *only your app*, not the entire device screen.

---

## 🧰 Features

- Start/Stop app-only screen recording

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ac_widget_recorder:
````

---

## ⚙️ Android Setup

1. **Permissions** (Add in `android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_INTERNAL_STORAGE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

2. **Minimum SDK Version** (in `android/app/build.gradle`):

```gradle
defaultConfig {
  minSdkVersion 24
}
```

3. **Enable View Recording** (if using MediaProjection internally):

Some Android versions may require additional permission handling for screen capture APIs.

---

## 🍎 iOS Setup

1. **Permissions** (in `ios/Runner/Info.plist`):

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save the recorded screen to your photo library.</string>
```

2. **Minimum iOS Version**: `iOS 12.0+` recommended

3. **Post-processing**: iOS may require moving saved files to the app's document directory or Photos library for access.

---

## 🚀 Usage

```dart
import 'package:ac_widget_recorder/ac_widget_recorder.dart';

final controller = RecorderController(fps:  8);

// Start recording
String? filePath = await controller.startRecording();

// Stop recording and share
String? filePath = await controller.stopRecording();
```

---

## 📂 Output

The recorded file is saved locally (`.mp4`).
You can pass the output file name as a parameter to `startRecording()`.

---

## 📱 Example

Check the `example/` directory for a fully working app.

---

## 🔐 Notes

* Android '9+ may require scoped storage handling
* Recording **starts after build**; consider a small delay before invoking

---

## 💬 Issues & Feedback

Feel free to [open an issue](https://github.com/anycode/ac_widget_recorder.flutter/issues) or contribute a PR!

---

## 📝 License

MIT License © 2026 Martin Edlman (Anycode)

```

### flutter pub publish --dry-run
### flutter pub publish
