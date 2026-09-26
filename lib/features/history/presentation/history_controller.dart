import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfword_pro/core/config/app_env.dart';
import 'package:pdfword_pro/core/files/docx_open_service.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/real/supabase_ocr_service.dart';
import 'package:pdfword_pro/features/shared/repositories/history_repository.dart';

class HistoryViewState {
  const HistoryViewState({
    required this.items,
    required this.downloadingIds,
    this.lastOpenedId,
    this.statusMessage,
  });

  final List<ConversionHistoryItem> items;
  final Set<String> downloadingIds;
  final String? lastOpenedId;
  final String? statusMessage;

  Map<HistoryGroup, List<ConversionHistoryItem>> get groupedItems {
    final grouped = <HistoryGroup, List<ConversionHistoryItem>>{
      HistoryGroup.today: [],
      HistoryGroup.yesterday: [],
      HistoryGroup.lastWeek: [],
    };
    for (final item in items) {
      grouped[item.group]?.add(item);
    }
    return grouped;
  }

  HistoryViewState copyWith({
    List<ConversionHistoryItem>? items,
    Set<String>? downloadingIds,
    String? lastOpenedId,
    String? statusMessage,
    bool clearLastOpened = false,
    bool clearStatusMessage = false,
  }) {
    return HistoryViewState(
      items: items ?? this.items,
      downloadingIds: downloadingIds ?? this.downloadingIds,
      lastOpenedId:
          clearLastOpened ? null : (lastOpenedId ?? this.lastOpenedId),
      statusMessage:
          clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

class HistoryController extends StateNotifier<HistoryViewState> {
  HistoryController(
    HistoryRepository repository, {
    SupabaseOcrService? ocrService,
    DocxOpenService? docxOpenService,
  })  : _ocrService = ocrService,
        _docxOpenService = docxOpenService ?? ShareSheetDocxOpenService(),
        super(
          HistoryViewState(
            items: repository.seedHistory(),
            downloadingIds: <String>{},
          ),
        ) {
    _loadFromBackend();
  }

  final SupabaseOcrService? _ocrService;
  final DocxOpenService _docxOpenService;
  static const String _mockDocxAssetPath = 'assets/mock/converted_sample.docx';

  Future<void> refresh() async {
    await _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    final ocrService = _ocrService;
    if (ocrService == null) return;
    final remote = await ocrService.fetchRecent(limit: 40);
    if (remote.isEmpty) return;
    state = state.copyWith(items: remote);
  }

  void clearStatusMessage() {
    state = state.copyWith(clearStatusMessage: true);
  }

  void onHistoryItemTap(String id) {
    state = state.copyWith(lastOpenedId: id);
  }

  Future<void> onDownloadTap(ConversionHistoryItem item) async {
    final ocrService = _ocrService;
    if (ocrService == null) {
      if (AppEnv.useRealBackend && !AppEnv.canUseSupabase) {
        final missing = AppEnv.missingSupabaseConfig.join(', ');
        state =
            state.copyWith(statusMessage: 'Backend config missing: $missing');
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
    if (state.downloadingIds.contains(item.id)) return;
    if (!item.showDownload) {
      state = state.copyWith(statusMessage: 'File is not ready for download.');
      return;
    }

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

    final nextDownloading = <String>{...state.downloadingIds, item.id};
    state = state.copyWith(
      downloadingIds: nextDownloading,
      statusMessage: 'Preparing download link...',
    );

    final signedUrl = await ocrService.getSignedDownloadUrl(item.id);
    if (signedUrl == null || signedUrl.isEmpty) {
      _removeDownloading(item.id);
      state = state.copyWith(statusMessage: 'Could not get signed URL.');
      return;
    }

    final opened = await _docxOpenService.openFromSignedUrl(
      signedUrl: signedUrl,
      suggestedFileName: item.name,
    );
    _removeDownloading(item.id);
    state = state.copyWith(
      statusMessage: opened.isOpened
          ? 'DOCX is ready. Select the app to open it.'
          : 'Could not open DOCX. Tap download again.',
    );
  }

  void _removeDownloading(String id) {
    final next = <String>{...state.downloadingIds}..remove(id);
    state = state.copyWith(downloadingIds: next);
  }
}
