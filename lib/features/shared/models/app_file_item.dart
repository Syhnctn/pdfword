import 'dart:typed_data';

import 'package:pdfword_pro/features/shared/models/upload_state.dart';

class AppFileItem {
  const AppFileItem({
    required this.id,
    required this.name,
    required this.sizeMb,
    required this.state,
    required this.progress,
    this.bytes,
    this.mimeType,
  });

  final String id;
  final String name;
  final double sizeMb;
  final UploadState state;
  final double progress;
  final Uint8List? bytes;
  final String? mimeType;

  String get sizeLabel => '${sizeMb.toStringAsFixed(1)} MB';

  AppFileItem copyWith({
    String? id,
    String? name,
    double? sizeMb,
    UploadState? state,
    double? progress,
    Uint8List? bytes,
    String? mimeType,
    bool clearBytes = false,
  }) {
    return AppFileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sizeMb: sizeMb ?? this.sizeMb,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      bytes: clearBytes ? null : (bytes ?? this.bytes),
      mimeType: mimeType ?? this.mimeType,
    );
  }
}
