// This file creates placeholder images for the games
// Run this once to generate the placeholder images in assets/images/

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> generatePlaceholderImages() async {
  // Generate step_sequencing placeholder
  await generateImage(
    'step_sequencing',
    Colors.grey.shade200,
    Icons.list_rounded,
  );

  // Generate story_reading placeholder
  await generateImage(
    'story_reading',
    Colors.grey.shade200,
    Icons.book,
  );

  // Generate reaction_time placeholder
  await generateImage(
    'reaction_time',
    Colors.grey.shade200,
    Icons.flash_on,
  );
}

Future<void> generateImage(String name, Color bgColor, IconData icon) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Draw background
  canvas.drawRect(
    Rect.fromLTWH(0, 0, 200, 160),
    Paint()..color = bgColor,
  );

  // Draw icon
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 64,
        fontFamily: icon.fontFamily,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (200 - textPainter.width) / 2,
      (160 - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(200, 160);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  // Save byteData to file: assets/images/$name.png
}
