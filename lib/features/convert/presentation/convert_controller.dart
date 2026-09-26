import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfword_pro/core/config/app_env.dart';
import 'package:pdfword_pro/core/files/docx_open_service.dart';
import 'package:pdfword_pro/core/files/local_docx_store.dart';
import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/models/upload_state.dart';
import 'package:pdfword_pro/features/shared/real/supabase_ocr_service.dart';
import 'package:pdfword_pro/features/shared/repositories/conversion_repository.dart';

class ConvertViewState {
  const ConvertViewState({
    required this.selectedFiles,
    required this.recentConversions,
    required this.isConverting,
    required this.downloadingRecentIds,
    this.activeJobId,
    this.statusMessage,
    this.pendingPreview,
  });

  final List<AppFileItem> selectedFiles;
  final List<ConversionHistoryItem> recentConversions;
  final bool isConverting;
  final Set<String> downloadingRecentIds;
  final String? activeJobId;
  final String? statusMessage;

  /// Set after a successful conversion; the screen opens the preview once.
  final ConversionHistoryItem? pendingPreview;

  double get totalSizeMb {
    return selectedFiles.fold<double>(0, (sum, item) => sum + item.sizeMb);
  }

  String get totalSizeLabel => '${totalSizeMb.toStringAsFixed(1)} MB';

  ConvertViewState copyWith({
    List<AppFileItem>? selectedFiles,
    List<ConversionHistoryItem>? recentConversions,
    bool? isConverting,
    Set<String>? downloadingRecentIds,
    String? activeJobId,
    String? statusMessage,
    ConversionHistoryItem? pendingPreview,
    bool clearActiveJobId = false,
    bool clearStatusMessage = false,
    bool clearPendingPreview = false,
  }) {
    return ConvertViewState(
      selectedFiles: selectedFiles ?? this.selectedFiles,
      recentConversions: recentConversions ?? this.recentConversions,
      isConverting: isConverting ?? this.isConverting,
      downloadingRecentIds: downloadingRecentIds ?? this.downloadingRecentIds,
      activeJobId: clearActiveJobId ? null : (activeJobId ?? this.activeJobId),
      statusMessage:
          clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      pendingPreview: clearPendingPreview
          ? null
          : (pendingPreview ?? this.pendingPreview),
    );
  }
}

class ConvertController extends StateNotifier<ConvertViewState> {
  ConvertController(
    ConversionRepository repository, {
    SupabaseOcrService? ocrService,
    DocxOpenService? docxOpenService,
    LocalDocxStore? localDocxStore,
    Future<String> Function()? deviceIdHashResolver,
    void Function(ConversionHistoryItem item)? onLocalConversion,
  })  : _ocrService = ocrService,
        _docxOpenService = docxOpenService ?? ShareSheetDocxOpenService(),
        _localDocxStore = localDocxStore ?? LocalDocxStore(),
        _deviceIdHashResolver = deviceIdHashResolver,
        _onLocalConversion = onLocalConversion,
        super(
          ConvertViewState(
            selectedFiles: repository.seedSelectedFiles(),
            recentConversions: repository.seedRecentConversions(),
            isConverting: false,
            downloadingRecentIds: <String>{},
          ),
        );

  final SupabaseOcrService? _ocrService;
  final DocxOpenService _docxOpenService;
  final LocalDocxStore _localDocxStore;
  final Future<String> Function()? _deviceIdHashResolver;
  final void Function(ConversionHistoryItem item)? _onLocalConversion;
  static const String _mockDocxAssetPath = 'assets/mock/converted_sample.docx';

  /// Stable guest identifier. The daily_usage unique index collapses guest
  /// usage into a single `anon` key, so a per-run id would break quota
  /// lookups on the second conversion of the day.
  static const String _guestDeviceIdHash = 'guest';

  void onAddPickedFiles(List<AppFileItem> files) {
    if (files.isEmpty) return;

    final existing = state.selectedFiles;
    final merged = <AppFileItem>[...files];
    for (final item in existing) {
      final duplicate = files.any((picked) => picked.id == item.id);
      if (!duplicate) merged.add(item);
    }

    state = state.copyWith(
      selectedFiles: merged,
      clearStatusMessage: true,
    );
  }

  void onRemoveFile(String fileId) {
    state = state.copyWith(
      selectedFiles: state.selectedFiles
          .where((file) => file.id != fileId)
          .toList(growable: false),
    );
  }

  void clearStatusMessage() {
    state = state.copyWith(clearStatusMessage: true);
  }

  Future<void> onRecentDownloadTap(ConversionHistoryItem item) async {
    final ocrService = _ocrService;
    if (ocrService == null) {
      if (AppEnv.useRealBackend && !AppEnv.canUseSupabase) {
        final missing = AppEnv.missingSupabaseConfig.join(', ');
        state = state.copyWith(
          statusMessage: 'Backend config missing: $missing',
        );
        return;
      }
      final opened = await _docxOpenService.openFromAsset(
        assetPath: _mockDocxAssetPath,
        suggestedFileName: item.name,
      );
      state = state.copyWith(
        statusMessage: opened.isOpened
            ? 'Mock DOCX is ready. Select the app to open it.'
            : 'Mock DOCX could not be opened. Try again.',
      );
      return;
    }
    if (!item.showDownload) {
      state = state.copyWith(statusMessage: 'File is not ready for download.');
      return;
    }
    if (state.downloadingRecentIds.contains(item.id)) return;

    // Direct-convert results are saved on-device; open them without network.
    final localPath = item.outputDocxPath;
    if (localPath != null && localPath.isNotEmpty) {
      try {
        final localFile = File(localPath);
        if (await localFile.exists()) {
          final bytes = await localFile.readAsBytes();
          final opened = await _docxOpenService.openFromBytes(
            bytes: bytes,
            suggestedFileName: item.name,
          );
          state = state.copyWith(
            statusMessage: opened.isOpened
                ? 'DOCX is ready. Select the app to open it.'
                : 'Could not open DOCX. Try again.',
          );
          return;
        }
      } catch (_) {
        // Fall through to the signed URL path.
      }
    }

    final next = <String>{...state.downloadingRecentIds, item.id};
    state = state.copyWith(
      downloadingRecentIds: next,
      statusMessage: 'Preparing download link...',
    );

    final signedUrl = await ocrService.getSignedDownloadUrl(item.id);
    if (signedUrl == null || signedUrl.isEmpty) {
      _removeRecentDownloading(item.id);
      state = state.copyWith(statusMessage: 'Could not get signed URL.');
      return;
    }

    final opened = await _docxOpenService.openFromSignedUrl(
      signedUrl: signedUrl,
      suggestedFileName: item.name,
    );
    _removeRecentDownloading(item.id);
    state = state.copyWith(
      statusMessage: opened.isOpened
          ? 'DOCX is ready. Select the app to open it.'
          : 'Could not open DOCX. Tap download again.',
    );
  }

  Future<void> onConvertTap() async {
    if (state.selectedFiles.isEmpty || state.isConverting) return;

    final files = state.selectedFiles;
    final ocrService = _ocrService;

    state = state.copyWith(
      isConverting: true,
      statusMessage: 'Creating job...',
    );

    if (ocrService == null) {
      if (AppEnv.useRealBackend && !AppEnv.canUseSupabase) {
        final missing = AppEnv.missingSupabaseConfig.join(', ');
        state = state.copyWith(
          isConverting: false,
          statusMessage: 'Backend config missing: $missing',
        );
        return;
      }
      await _runFallbackLocalConversion();
      return;
    }

    final sizeLabel = state.totalSizeLabel;
    final createResult = await ocrService.createJob(
      files,
      deviceIdHash: await _resolveDeviceIdHash(),
    );
    if (createResult == null) {
      // Job creation unavailable (quota/edge issue) -> convert directly.
      await _runDirectConvert(ocrService, files, sizeLabel: sizeLabel);
      return;
    }

    final targetByFileId = {
      for (final target in createResult.uploadTargets) target.fileId: target,
    };

    state = state.copyWith(
      activeJobId: createResult.jobId,
      statusMessage: 'Uploading files...',
    );

    var storageUploadFailed = false;
    for (final file in files) {
      final target = targetByFileId[file.id];
      if (target == null || file.bytes == null) {
        storageUploadFailed = true;
        break;
      }

      _setFileState(
        file.id,
        file.copyWith(
          state: UploadState.uploading,
          progress: 0.25,
        ),
      );

      final uploaded = await ocrService.uploadFileToSignedUrl(
        target: target,
        file: file,
      );

      if (!uploaded) {
        // Signed storage upload blocked (e.g. missing storage RLS policy).
        storageUploadFailed = true;
        break;
      }

      _setFileState(
        file.id,
        file.copyWith(
          state: UploadState.ready,
          progress: 1.0,
        ),
      );
    }

    if (storageUploadFailed) {
      // Fall back to sending raw bytes straight to the OCR worker.
      await _runDirectConvert(
        ocrService,
        files,
        sizeLabel: sizeLabel,
        jobId: createResult.jobId,
      );
      return;
    }

    state = state.copyWith(statusMessage: 'Queued for processing...');
    final queued = await ocrService.enqueueJob(createResult.jobId);
    if (!queued) {
      _markFailure(
        'The converter did not accept the job. Please try again in a moment.',
      );
      return;
    }

    state = state.copyWith(
      statusMessage: 'Processing on OCR worker...',
      selectedFiles: state.selectedFiles
          .map(
            (file) => file.copyWith(
              state: UploadState.processing,
              progress: 1.0,
            ),
          )
          .toList(growable: false),
    );

    final status = await ocrService.pollJobUntilDone(
      createResult.jobId,
      // OCR on the free worker tier is slow: a single scanned page already
      // takes ~65s, so allow a long window before reporting a timeout.
      timeout: const Duration(minutes: 15),
      onTick: (tick) {
        final message = 'Processing... ${tick.progressPct}%';
        state = state.copyWith(statusMessage: message);
      },
    );

    if (status == null) {
      _markFailure('Processing timeout. Please try again.');
      return;
    }

    if (!status.isSuccess) {
      _markFailure(status.errorMessage ?? 'Job failed on worker.');
      return;
    }

    await _finishSuccess(
      jobId: createResult.jobId,
      inputName: files.first.name,
      outputDocxPath: status.outputDocxPath,
      sizeLabel: sizeLabel,
    );
  }

  /// Sends raw file bytes to the OCR worker directly. Used when the hosted
  /// job/signed-upload path is unavailable (RLS, quota, edge errors).
  Future<void> _runDirectConvert(
    SupabaseOcrService ocrService,
    List<AppFileItem> files, {
    required String sizeLabel,
    String? jobId,
  }) async {
    state = state.copyWith(
      statusMessage: 'Sending files directly to converter...',
      activeJobId: jobId,
    );

    final result = await ocrService.convertViaWorker(
      files: files,
      jobId: jobId,
    );
    if (result == null || !result.started) {
      _markFailure(
        'Conversion could not start. Please check your connection and try again.',
      );
      return;
    }

    final resolvedId = (result.jobId != null && result.jobId!.isNotEmpty)
        ? result.jobId!
        : (jobId ?? 'local-${DateTime.now().millisecondsSinceEpoch}');

    String? localPath;
    final docxBytes = result.docxBytes;
    if (docxBytes != null && docxBytes.isNotEmpty) {
      try {
        localPath = (await _localDocxStore.save(resolvedId, docxBytes)).path;
      } catch (_) {
        localPath = null;
      }
    }

    await _finishSuccess(
      jobId: resolvedId,
      inputName: files.first.name,
      outputDocxPath: result.outputDocxPath,
      localPath: localPath,
      sizeLabel: sizeLabel,
    );
  }

  Future<void> _finishSuccess({
    required String jobId,
    required String inputName,
    required String sizeLabel,
    String? outputDocxPath,
    String? localPath,
  }) async {
    final now = DateTime.now().toLocal();
    final subtitle =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute
            .toString()
            .padLeft(2, '0')}';
    final item = ConversionHistoryItem(
      id: jobId,
      name: _resolveOutputFileName(outputDocxPath, inputName, jobId),
      subtitle: subtitle,
      sizeLabel: sizeLabel,
      group: HistoryGroup.today,
      status: ConversionJobStatus.succeeded,
      outputDocxPath: localPath ?? outputDocxPath,
      showDownload: true,
    );

    state = state.copyWith(
      isConverting: false,
      selectedFiles: state.selectedFiles
          .map(
            (file) => file.copyWith(
              state: UploadState.ready,
              progress: 1.0,
              clearBytes: true,
            ),
          )
          .toList(growable: false),
      recentConversions: [
        item,
        ...state.recentConversions.where((recent) => recent.id != item.id),
      ].take(3).toList(growable: false),
      pendingPreview: item,
      statusMessage: 'Conversion completed. Opening preview...',
    );
    _onLocalConversion?.call(item);
  }

  void clearPendingPreview() {
    state = state.copyWith(clearPendingPreview: true);
  }

  /// Resolves the stable per-install device id for guest quota accounting,
  /// falling back to the legacy shared 'guest' bucket when unavailable.
  Future<String> _resolveDeviceIdHash() async {
    final resolver = _deviceIdHashResolver;
    if (resolver == null) return _guestDeviceIdHash;
    try {
      final id = await resolver();
      return id.trim().isEmpty ? _guestDeviceIdHash : id;
    } catch (_) {
      return _guestDeviceIdHash;
    }
  }

  void _setFileState(String fileId, AppFileItem next) {
    final updated = state.selectedFiles.map((file) {
      if (file.id == fileId) return next;
      return file;
    }).toList(growable: false);
    state = state.copyWith(selectedFiles: updated);
  }

  void _markFailure(String message) {
    state = state.copyWith(
      isConverting: false,
      statusMessage: message,
      selectedFiles: state.selectedFiles
          .map(
            (file) => file.state == UploadState.uploading ||
                    file.state == UploadState.processing
                ? file.copyWith(state: UploadState.failed)
                : file,
          )
          .toList(growable: false),
    );
  }

  Future<void> _runFallbackLocalConversion() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final convertedName = state.selectedFiles.first.name
        .replaceAll('.pdf', '.docx')
        .replaceAll('Scanned_', 'Converted_');

    final newRecent = ConversionHistoryItem(
      id: 'recent-${DateTime.now().millisecondsSinceEpoch}',
      name: convertedName,
      subtitle: 'Converted just now',
      sizeLabel: '920 KB',
      group: HistoryGroup.today,
      status: ConversionJobStatus.succeeded,
      outputDocxPath: 'mock/$convertedName',
      showDownload: true,
    );

    state = state.copyWith(
      isConverting: false,
      selectedFiles: state.selectedFiles
          .map((file) => file.copyWith(state: UploadState.ready, progress: 1))
          .toList(growable: false),
      recentConversions: [newRecent, ...state.recentConversions].take(3).toList(
            growable: false,
          ),
      statusMessage:
          'Mock conversion completed. Real DOCX download requires backend mode.',
    );
  }

  void _removeRecentDownloading(String id) {
    final next = <String>{...state.downloadingRecentIds}..remove(id);
    state = state.copyWith(downloadingRecentIds: next);
  }

  String _resolveOutputFileName(
    String? outputDocxPath,
    String inputName,
    String jobId,
  ) {
    final fromPath = _filenameFromPath(outputDocxPath);
    if (fromPath != null && fromPath.isNotEmpty) return fromPath;

    final normalized = inputName.toLowerCase();
    if (normalized.endsWith('.pdf')) {
      return '${inputName.substring(0, inputName.length - 4)}.docx';
    }
    if (normalized.endsWith('.docx')) return inputName;
    return 'converted_$jobId.docx';
  }

  String? _filenameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}
