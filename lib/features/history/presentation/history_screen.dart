import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfword_pro/app/router.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_details.dart';
import 'package:pdfword_pro/features/shared/models/conversion_history_item.dart';
import 'package:pdfword_pro/features/shared/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const routePath = '/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);
    final palette = context.palette;

    // Merge session-local conversions (backend list reads may be RLS-blocked).
    final localItems = ref.watch(localConversionsProvider);
    final extraLocal = localItems
        .where((local) => !state.items.any((item) => item.id == local.id))
        .toList(growable: false);
    final mergedItems = [...extraLocal, ...state.items];
    final grouped = <HistoryGroup, List<ConversionHistoryItem>>{
      for (final group in HistoryGroup.values) group: [],
    };
    for (final item in mergedItems) {
      grouped[item.group]?.add(item);
    }

    void openPreview(ConversionHistoryItem item) {
      context.push(
        AppRoutes.preview,
        extra: PreviewDetails.fromHistoryItem(item),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
      child: Column(
        key: const Key('screen_history'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.text('history'),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Pressable(
                onTap: controller.refresh,
                child: Text(
                  l10n.text('refresh'),
                  style: TextStyle(
                    fontSize: 18,
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (state.statusMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.infoBackground,
                borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 13,
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: palette.input,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: palette.textSecondary,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.text('searchConverted'),
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 70,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.input,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.tune,
                  color: palette.iconMuted,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _HistorySection(
            title: l10n.text('today'),
            items: grouped[HistoryGroup.today] ?? const [],
            downloadingIds: state.downloadingIds,
            onTap: controller.onHistoryItemTap,
            onDownloadTap: controller.onDownloadTap,
            onPreviewTap: openPreview,
          ),
          const SizedBox(height: 12),
          _HistorySection(
            title: l10n.text('yesterday'),
            items: grouped[HistoryGroup.yesterday] ?? const [],
            downloadingIds: state.downloadingIds,
            onTap: controller.onHistoryItemTap,
            onDownloadTap: controller.onDownloadTap,
            onPreviewTap: openPreview,
          ),
          const SizedBox(height: 12),
          _HistorySection(
            title: l10n.text('lastWeek'),
            items: grouped[HistoryGroup.lastWeek] ?? const [],
            downloadingIds: state.downloadingIds,
            onTap: controller.onHistoryItemTap,
            onDownloadTap: controller.onDownloadTap,
            onPreviewTap: openPreview,
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.items,
    required this.downloadingIds,
    required this.onTap,
    required this.onDownloadTap,
    required this.onPreviewTap,
  });

  final String title;
  final List<ConversionHistoryItem> items;
  final Set<String> downloadingIds;
  final ValueChanged<String> onTap;
  final ValueChanged<ConversionHistoryItem> onDownloadTap;
  final ValueChanged<ConversionHistoryItem> onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 2,
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Pressable(
              onTap: () => onTap(item.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF132851)
                            : palette.iconBoxBackground,
                        borderRadius: BorderRadius.circular(16),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.subtitle}  |  ${item.sizeLabel}',
                            style: TextStyle(
                              fontSize: 16,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(status: item.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.showDownload)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Pressable(
                            key: const Key('history_preview_button'),
                            onTap: () => onPreviewTap(item),
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
                            key: const Key('history_download_button'),
                            onTap: () => onDownloadTap(item),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: downloadingIds.contains(item.id)
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
                        Icons.more_vert,
                        color: palette.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ConversionJobStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    late final String label;
    late final Color textColor;
    late final Color bgColor;

    switch (status) {
      case ConversionJobStatus.succeeded:
        label = context.l10n.text('statusSucceeded');
        textColor = palette.success;
        bgColor = const Color(0x1F1ED9A1);
      case ConversionJobStatus.processing:
        label = context.l10n.text('statusProcessing');
        textColor = palette.primary;
        bgColor = const Color(0x1F2563FF);
      case ConversionJobStatus.queued:
        label = context.l10n.text('statusQueued');
        textColor = const Color(0xFF9DB1CF);
        bgColor = const Color(0x1F9DB1CF);
      case ConversionJobStatus.failed:
        label = context.l10n.text('statusFailed');
        textColor = palette.danger;
        bgColor = const Color(0x1FFF5A6B);
      case ConversionJobStatus.unknown:
        label = context.l10n.text('statusUnknown');
        textColor = palette.textSecondary;
        bgColor = const Color(0x1F8A97B3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
