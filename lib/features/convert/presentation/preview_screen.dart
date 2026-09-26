import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfword_pro/core/files/docx_preview_service.dart';
import 'package:pdfword_pro/core/i18n/app_localizations.dart';
import 'package:pdfword_pro/core/theme/app_colors.dart';
import 'package:pdfword_pro/core/widgets/app_gradient_background.dart';
import 'package:pdfword_pro/core/widgets/pressable.dart';
import 'package:pdfword_pro/features/convert/presentation/preview_details.dart';
import 'package:pdfword_pro/features/shared/providers.dart';

/// Full-screen preview of a converted Word document.
///
/// [loader] is injectable for tests; production uses [DocxPreviewService]
/// via providers (local file -> signed URL -> bundled sample fallback).
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key, this.details, this.loader});

  final PreviewDetails? details;
  final Future<PreviewLoadResult> Function()? loader;

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late Future<PreviewLoadResult> _future;
  PreviewLoadResult? _result;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PreviewLoadResult> _load() async {
    final loader = widget.loader;
    final Future<PreviewLoadResult> future;
    if (loader != null) {
      future = loader();
    } else {
      final details = widget.details;
      if (details == null) {
        future = Future.value(const PreviewLoadResult(blocks: []));
      } else {
        future = ref.read(docxPreviewServiceProvider).load(
              details,
              ocrService: ref.read(ocrServiceProvider),
            );
      }
    }

    final result = await future;
    // The "Open in Word" button reads _result outside the FutureBuilder, so the
    // result must be stored through setState. Assigning it inside the builder
    // does not schedule a rebuild and leaves the button disabled.
    if (mounted) {
      setState(() => _result = result);
    }
    return result;
  }

  void _retry() {
    setState(() {
      _result = null;
      _future = _load();
    });
  }

  Future<void> _openInWord(PreviewLoadResult result) async {
    final bytes = result.bytes;
    if (bytes == null || bytes.isEmpty || _opening) return;
    setState(() => _opening = true);
    try {
      final opened = await ref.read(docxOpenServiceProvider).openFromBytes(
            bytes: bytes,
            suggestedFileName:
                widget.details?.fileName ?? 'converted_document.docx',
          );
      if (!opened.isOpened && mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.text('previewOpenFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final details = widget.details;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            key: const Key('screen_preview'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
                child: Row(
                  children: [
                    Pressable(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back, size: 26),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.text('preview'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            details?.fileName ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: palette.divider),
              Expanded(
                child: FutureBuilder<PreviewLoadResult>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: palette.primary),
                            const SizedBox(height: 14),
                            Text(
                              l10n.text('previewLoading'),
                              style: TextStyle(color: palette.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return _PreviewMessage(
                        icon: Icons.error_outline,
                        message: l10n.text('previewFailed'),
                        actionLabel: l10n.text('retry'),
                        onAction: _retry,
                      );
                    }

                    final result = snapshot.data!;
                    if (result.isEmpty) {
                      return _PreviewMessage(
                        icon: Icons.description_outlined,
                        message: l10n.text('previewEmpty'),
                        actionLabel: l10n.text('retry'),
                        onAction: _retry,
                      );
                    }

                    final blocks = result.blocks;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: blocks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _PreviewBlockView(block: blocks[index]);
                      },
                    );
                  },
                ),
              ),
              _buildOpenButton(context, l10n, palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenButton(
    BuildContext context,
    AppLocalizations l10n,
    AppPalette palette,
  ) {
    final canOpen = _result?.bytes != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Pressable(
        onTap: canOpen ? () => _openInWord(_result!) : null,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: canOpen ? palette.primary : palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Center(
            child: _opening
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.text('openInWord'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: canOpen ? Colors.white : palette.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Pressable(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBlockView extends StatelessWidget {
  const _PreviewBlockView({required this.block});

  final PreviewBlock block;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    switch (block.type) {
      case PreviewBlockType.pageBreak:
        return Row(
          children: [
            Expanded(child: Divider(color: palette.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.arrow_downward,
                size: 16,
                color: palette.textSecondary,
              ),
            ),
            Expanded(child: Divider(color: palette.divider)),
          ],
        );
      case PreviewBlockType.title:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        );
      case PreviewBlockType.heading:
        return Text(
          block.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        );
      case PreviewBlockType.subheading:
        return Text(
          block.text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        );
      case PreviewBlockType.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•  ',
              style: TextStyle(
                fontSize: 15,
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: Text(
                block.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        );
      case PreviewBlockType.paragraph:
        return Text(
          block.text,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: palette.textPrimary,
          ),
        );
    }
  }
}