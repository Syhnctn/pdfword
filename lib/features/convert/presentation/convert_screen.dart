import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfword_pro/app/router.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';
import 'package:pdfword_pro/features/convert/presentation/convert_controller.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_details.dart';
import 'package:pdfword_pro/features/shared/models/app_file_item.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/models/upload_state.dart';
import 'package:pdfword_pro/features/shared/providers.dart';

class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});

  static const routePath = AppRoutes.convert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(convertControllerProvider);
    final controller = ref.read(convertControllerProvider.notifier);
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(convertInterstitialAdGateProvider);

    // Auto-open the in-app preview after a successful conversion.
    ref.listen(
      convertControllerProvider.select((view) => view.pendingPreview),
      (previous, next) {
        if (next == null) return;
        controller.clearPendingPreview();
        context.push(
          AppRoutes.preview,
          extra: PreviewDetails.fromHistoryItem(next),
        );
      },
    );

    final media = MediaQuery.sizeOf(context);
    final isCompact = media.height < 760;
    final isNarrow = media.width < 390;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              key: const Key('screen_convert'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                _buildHeader(context, l10n, palette, isCompact),
                const SizedBox(height: 18),
                _buildUploadZone(
                  context,
                  l10n,
                  palette,
                  isDark,
                  isCompact,
                  controller,
                ),
                const SizedBox(height: 20),
                ..._buildSelectedFiles(
                  l10n,
                  palette,
                  isDark,
                  isCompact,
                  state,
                  controller,
                ),
                ..._buildRecentConversions(
                  context,
                  l10n,
                  palette,
                  isCompact,
                  state,
                  controller,
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(
          ref,
          l10n,
          palette,
          isCompact,
          isNarrow,
          state,
          controller,
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AppPalette palette,
    bool isCompact,
  ) {
    return Row(
      children: [
        Container(
          width: isCompact ? 46 : 52,
          height: isCompact ? 46 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: palette.glow,
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: const Color(0xFF0B2DB1),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.text('appName'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 18 : 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.text('converterPro'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Pressable(
          onTap: () => context.go(AppRoutes.settings),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.settings,
              size: isCompact ? 30 : 34,
              color: palette.iconMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadZone(
    BuildContext context,
    AppLocalizations l10n,
    AppPalette palette,
    bool isDark,
    bool isCompact,
    ConvertController controller,
  ) {
    return Pressable(
      key: const Key('upload_zone'),
      onTap: () => _pickFiles(context, controller),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(24),
        dashPattern: const [10, 8],
        strokeWidth: 1.6,
        color: palette.cardBorder,
        child: Container(
          height: isCompact ? 210 : 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x44121E36)
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isCompact ? 78 : 102,
                height: isCompact ? 78 : 102,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF11254B)
                      : palette.iconBoxBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: 44,
                  color: palette.primary,
                ),
              ),
              SizedBox(height: isCompact ? 12 : 22),
              Text(
                l10n.text('uploadPdf'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 28 : 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: isCompact ? 6 : 8),
              Text(
                l10n.text('uploadHint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 15,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.text('tapToUploadMock'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  color: palette.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectedFiles(
    AppLocalizations l10n,
    AppPalette palette,
    bool isDark,
    bool isCompact,
    ConvertViewState state,
    ConvertController controller,
  ) {
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              l10n.text('selectedFiles'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 22 : 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2E68) : const Color(0xFFDCE8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.selectedFiles.length} ${l10n.text('files')}',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF9EC1FF) : const Color(0xFF1547BF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (state.selectedFiles.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(palette),
          child: Text(
            l10n.text('noFilesSelected'),
            style: TextStyle(color: palette.textSecondary),
          ),
        )
      else
        ...state.selectedFiles.map(
          (file) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectedFileCard(
              item: file,
              onRemove: () => controller.onRemoveFile(file.id),
            ),
          ),
        ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildRecentConversions(
    BuildContext context,
    AppLocalizations l10n,
    AppPalette palette,
    bool isCompact,
    ConvertViewState state,
    ConvertController controller,
  ) {
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              l10n.text('recentConversions'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 22 : 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Text(
            l10n.text('viewAll'),
            style: TextStyle(
              fontSize: isCompact ? 14 : 16,
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (state.recentConversions.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(palette),
          child: Text(
            l10n.text('queued'),
            style: TextStyle(color: palette.textSecondary),
          ),
        )
      else
        ...state.recentConversions.take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentConversionCard(
                  item: item,
                  isDownloading: state.downloadingRecentIds.contains(item.id),
                  onDownloadTap: () => controller.onRecentDownloadTap(item),
                  onPreviewTap: () => context.push(
                    AppRoutes.preview,
                    extra: PreviewDetails.fromHistoryItem(item),
                  ),
                ),
              ),
            ),
    ];
  }

  Widget _buildBottomBar(
    WidgetRef ref,
    AppLocalizations l10n,
    AppPalette palette,
    bool isCompact,
    bool isNarrow,
    ConvertViewState state,
    ConvertController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.statusMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: palette.infoBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: palette.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.statusMessage!,
                      maxLines: isNarrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: isCompact ? 12 : 13,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: controller.clearStatusMessage,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 10 : 12,
              vertical: isCompact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: palette.subtleBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.text('totalSize')}: ${state.totalSizeLabel}',
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 15,
                    color: palette.textSecondary,
                  ),
                ),
                Text(
                  '${l10n.text('estTime')}: ${l10n.text('lessThanFiveSec')}',
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 15,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: state.isConverting
                ? null
                : () => _onConvertTapWithInterstitial(ref, controller),
            child: Container(
              width: double.infinity,
              height: isCompact ? 64 : 72,
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: palette.glow,
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Center(
                child: state.isConverting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.text('processing'),
                            style: TextStyle(
                              fontSize: isCompact ? 17 : 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '${l10n.text('convertToWord')}  ->',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onConvertTapWithInterstitial(
    WidgetRef ref,
    ConvertController controller,
  ) async {
    final adGate = ref.read(convertInterstitialAdGateProvider);
    await adGate.showThenRun(controller.onConvertTap);
  }

  BoxDecoration _cardDecoration(AppPalette palette) {
    return BoxDecoration(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: palette.cardBorder),
    );
  }

  Future<void> _pickFiles(
    BuildContext context,
    ConvertController controller,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = <AppFileItem>[];
    for (var i = 0; i < result.files.length; i++) {
      final file = result.files[i];
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final id = 'picked-${DateTime.now().microsecondsSinceEpoch}-$i';
      final sizeMb = file.size / (1024 * 1024);
      picked.add(
        AppFileItem(
          id: id,
          name: file.name,
          sizeMb: sizeMb,
          state: UploadState.queued,
          progress: 0,
          bytes: bytes,
          mimeType: _mimeTypeFromFileName(file.name),
        ),
      );
    }
    if (picked.isEmpty || !context.mounted) return;
    controller.onAddPickedFiles(picked);
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.item,
    required this.onRemove,
  });

  final AppFileItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final statusLabel = switch (item.state) {
      UploadState.queued => l10n.text('queued'),
      UploadState.uploading => l10n.text('uploading'),
      UploadState.processing => l10n.text('processing'),
      UploadState.ready => l10n.text('ready'),
      UploadState.failed => l10n.text('failed'),
    };

    final statusColor = switch (item.state) {
      UploadState.ready => palette.success,
      UploadState.failed => palette.danger,
      _ => palette.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF311F3C) : const Color(0xFFF5EAF1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SvgPicture.asset('assets/icons/file_pdf.svg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.sizeLabel,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '|',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.state == UploadState.uploading) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: item.progress),
                    duration: const Duration(milliseconds: 220),
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? const Color(0xFF364764)
                              : const Color(0xFFD6E1F2),
                          color: palette.primary,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: onRemove,
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                size: 22,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentConversionCard extends StatelessWidget {
  const _RecentConversionCard({
    required this.item,
    required this.isDownloading,
    required this.onDownloadTap,
    required this.onPreviewTap,
  });

  final ConversionHistoryItem item;
  final bool isDownloading;
  final VoidCallback onDownloadTap;
  final VoidCallback onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? palette.card.withValues(alpha: 0.82) : palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF0F2245) : palette.iconBoxBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SvgPicture.asset('assets/icons/file_doc.svg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (item.showDownload)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pressable(
                  key: const Key('recent_preview_button'),
                  onTap: onPreviewTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.visibility_outlined,
                      size: 22,
                      color: palette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Pressable(
                  key: const Key('recent_download_button'),
                  onTap: onDownloadTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.primary,
                            ),
                          )
                        : Icon(
                            Icons.download_rounded,
                            color: palette.primary,
                          ),
                  ),
                ),
              ],
            )
          else
            Icon(
              Icons.more_horiz,
              color: palette.textSecondary,
            ),
        ],
      ),
    );
  }
}
