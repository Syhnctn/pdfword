enum HistoryGroup {
  today,
  yesterday,
  lastWeek,
}

enum ConversionJobStatus {
  queued,
  processing,
  succeeded,
  failed,
  unknown,
}

class ConversionHistoryItem {
  const ConversionHistoryItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.sizeLabel,
    required this.group,
    required this.status,
    this.outputDocxPath,
    this.showDownload = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final String sizeLabel;
  final HistoryGroup group;
  final ConversionJobStatus status;
  final String? outputDocxPath;
  final bool showDownload;

  ConversionHistoryItem copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? sizeLabel,
    HistoryGroup? group,
    ConversionJobStatus? status,
    String? outputDocxPath,
    bool? showDownload,
    bool clearOutputDocxPath = false,
  }) {
    return ConversionHistoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      group: group ?? this.group,
      status: status ?? this.status,
      outputDocxPath:
          clearOutputDocxPath ? null : (outputDocxPath ?? this.outputDocxPath),
      showDownload: showDownload ?? this.showDownload,
    );
  }
}
