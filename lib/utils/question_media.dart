import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:quizzapp/data/models/quiz_model.dart';

/// Image-handling helpers for question media (`Question.mediaPath`).
///
/// Two storage formats coexist:
///   * **File path** — what the host saves locally after a pick. Fast to load.
///   * **`data:image/jpeg;base64,…` URI** — what is sent over the wire to
///     clients (so they can render without filesystem access).
///
/// `renderQuestionImage` accepts either. `pickAndStoreImage` always returns a
/// file path (or null on cancel); `toTransportable` upgrades a file path to a
/// data URI before broadcasting.
class QuestionMedia {
  QuestionMedia._();

  /// Hard cap on transmitted image size — keeps `QuestionMessage` payloads
  /// small enough that a 300-client broadcast stays manageable on a phone host.
  /// 600 px wide at quality 60 typically yields 30–80 KB; we further refuse
  /// anything larger than this after encoding.
  static const int maxBytes = 200 * 1024;

  /// Picks an image from gallery (or camera if [fromCamera] is true), copies
  /// it into the app's documents directory, and returns the absolute file
  /// path. Returns null if the user cancels.
  static Future<String?> pickAndStoreImage(ImagePicker picker,
      {bool fromCamera = false}) async {
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 65,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(dir.path, 'media'));
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    final ext = p.extension(picked.path).isEmpty
        ? '.jpg'
        : p.extension(picked.path);
    final dest = p.join(mediaDir.path, '${const Uuid().v4()}$ext');
    await File(picked.path).copy(dest);
    return dest;
  }

  /// Converts a local file path to a `data:` URI suitable for inclusion in a
  /// network message. If the file is missing or exceeds [maxBytes] after
  /// encoding, returns null (caller should skip transmitting the image).
  static Future<String?> toTransportable(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:')) return path; // already a data URI
    final f = File(path);
    if (!await f.exists()) return null;
    final bytes = await f.readAsBytes();
    if (bytes.lengthInBytes > maxBytes) return null;
    final mime = _mimeFromExt(p.extension(path).toLowerCase());
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  /// Renders a question image. Accepts either a file path or a data URI.
  /// Falls back to an empty SizedBox if the source can't be resolved.
  static Widget render(String? source,
      {double? height,
      BoxFit fit = BoxFit.cover,
      BorderRadius? borderRadius}) {
    if (source == null || source.isEmpty) return const SizedBox.shrink();
    final br = borderRadius ?? BorderRadius.circular(12);
    Widget child;
    if (source.startsWith('data:')) {
      try {
        final base64Part = source.split(',').last;
        child = Image.memory(
          base64Decode(base64Part),
          fit: fit,
          height: height,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else {
      child = Image.file(
        File(source),
        fit: fit,
        height: height,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return ClipRRect(borderRadius: br, child: child);
  }

  /// Returns a copy of [question]'s map suitable for transmission: any local
  /// file path in `mediaPath` is upgraded to a data URI; if encoding fails or
  /// the file is too large, `mediaPath` is dropped from the map (clients will
  /// just render text).
  static Future<Map<String, dynamic>> toTransportableMap(
      Question question) async {
    final map = question.toMap();
    final transported = await toTransportable(question.mediaPath);
    if (transported == null) {
      map['mediaPath'] = null;
    } else {
      map['mediaPath'] = transported;
    }
    return map;
  }

  static String _mimeFromExt(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
