import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nearbuddy/theme/nearbuddy_logo.dart';

/// Renders [painter] to a PNG file at [path] (relative to the package root).
Future<void> renderPng(
  String path,
  int size,
  CustomPainter painter,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render NearBuddy launcher icons', () async {
    final res = 'android${Platform.pathSeparator}app'
        '${Platform.pathSeparator}src${Platform.pathSeparator}main'
        '${Platform.pathSeparator}res';

    // Adaptive-icon foreground: 432x432 (108dp @ 4x), transparent background
    // (the blue comes from the ic_launcher_background color resource), glyph
    // inside the 66dp safe zone (~66% of the canvas).
    await renderPng(
      '$res${Platform.pathSeparator}drawable'
      '${Platform.pathSeparator}ic_launcher_foreground.png',
      432,
      const NearBuddyLogoPainter(),
    );

    // Monochrome variant (themed icons): white glyph on transparent.
    await renderPng(
      '$res${Platform.pathSeparator}drawable'
      '${Platform.pathSeparator}ic_launcher_monochrome.png',
      432,
      const NearBuddyLogoPainter(),
    );

    // Legacy square icons (API 23–25): full-bleed brand-blue background.
    const legacy = <String, int>{
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };
    for (final entry in legacy.entries) {
      await renderPng(
        '$res${Platform.pathSeparator}${entry.key}'
        '${Platform.pathSeparator}ic_launcher.png',
        entry.value,
        const NearBuddyLogoPainter(drawBackground: true),
      );
    }

    // Sanity check the generated files exist and are non-trivial in size.
    final dir = Directory('$res${Platform.pathSeparator}drawable');
    final fg = File('${dir.path}${Platform.pathSeparator}'
        'ic_launcher_foreground.png');
    expect(fg.existsSync(), isTrue);
    expect(fg.lengthSync(), greaterThan(1000),
        reason: 'foreground PNG should not be empty');

    final legacyDir = Directory(
      '$res${Platform.pathSeparator}mipmap-xxxhdpi',
    );
    final legacyFile = File('${legacyDir.path}${Platform.pathSeparator}'
        'ic_launcher.png');
    expect(legacyFile.existsSync(), isTrue);
    expect(legacyFile.lengthSync(), greaterThan(1000),
        reason: 'legacy icon PNG should not be empty');
  });
}
