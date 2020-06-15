# variosound

Flutter plugin to generate the sound of a variometer.

⚠️ ONLY FOR ANDROID AT THE MOMENT

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.


## API

| Method    | Return value | Parameters   |
| --------- | ------------ | ------------ |
| play      | void         |              |
| stop      | void         |              |
| setSpeed  | void         | double speed |
| isPlaying | boolean      |              |

## Usage

```dart
// To init the Audio stream - speed is set at zero initially
Variosound.play();

// Pass the speed (in meter per second) to change the sound frequency, duration and duty
Variosound.setSpeed(3.0);

// Check if playing (for thresholds for example)
Variosound.isPlaying()

// Stop playing
Variosound.stop();

```