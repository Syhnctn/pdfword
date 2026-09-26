import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';

/// Navigation payload for the in-app DOCX preview screen.
class PreviewDetails {
  const PreviewDetails({
    required this.jobId,
    required this.fileName,
    this.localPath,
  });

  /// Supabase job id (or a local id for direct conversions).
  final String jobId;

  /// Suggested file name shown in the preview app bar.
  final String fileName;

  /// Absolute local path when the DOCX was saved on-device.
  final String? localPath;

  factory PreviewDetails.fromHistoryItem(ConversionHistoryItem item) {
    final path = item.outputDocxPath;
    final isLocal = path != null && path.isNotEmpty && _looksLikeLocalPath(path);
    return PreviewDetails(
      jobId: item.id,
      fileName: item.name,
      localPath: isLocal ? path : null,
    );
  }

  static bool _looksLikeLocalPath(String path) {
    if (path.startsWith('/')) return true;
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }
}