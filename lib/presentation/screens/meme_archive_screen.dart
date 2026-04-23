import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/layout/home_tab_scroll_padding.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';

class MemeArchiveScreen extends StatefulWidget {
  const MemeArchiveScreen({super.key});

  @override
  State<MemeArchiveScreen> createState() => _MemeArchiveScreenState();
}

class _MemeArchiveScreenState extends State<MemeArchiveScreen> {
  final _repo = MemeLocalArchiveRepository.instance;
  List<MemeArchiveEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.onChanged.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _repo.onChanged.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await _repo.loadEntries();
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime d) {
    return '${_twoDigits(d.day)}.${_twoDigits(d.month)}.${d.year} · ${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';
  }

  Future<void> _openFull(MemeArchiveEntry e) async {
    final l10n = AppLocalizations.of(context);
    final file = await _repo.fileFor(e);
    if (!mounted) {
      return;
    }
    if (!await file.exists()) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.archiveFileMissing)),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          backgroundColor: MemeopsColors.bgMid,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.25),
            foregroundColor: Colors.white,
            title: Text(e.sourceLabel, style: const TextStyle(fontSize: 17)),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(MemeopsRadii.md),
                child: InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4,
                  child: Image.file(file, fit: BoxFit.contain),
                ),
              ),
              if (e.caption != null && e.caption!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  e.caption!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.archiveTitle, style: MemeopsTextStyles.sectionTitle(context)),
              const SizedBox(height: 4),
              Text(
                l10n.archiveSubtitle,
                style: MemeopsTextStyles.caption(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: _entries.isEmpty
                      ? ListView(
                          padding: homeTabScrollPadding().copyWith(top: 0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.15,
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  l10n.archiveEmpty,
                                  textAlign: TextAlign.center,
                                  style: MemeopsTextStyles.caption(context),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: homeTabScrollPadding().copyWith(top: 0),
                          itemCount: _entries.length,
                          itemBuilder: (context, i) {
                            final e = _entries[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MemeopsGlassSurface(
                                padding: const EdgeInsets.all(12),
                                borderRadius: MemeopsRadii.md,
                                child: InkWell(
                                  onTap: () => _openFull(e),
                                  borderRadius: BorderRadius.circular(
                                    MemeopsRadii.md,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          MemeopsRadii.sm,
                                        ),
                                        child: FutureBuilder<File>(
                                          future: _repo.fileFor(e),
                                          builder: (context, snap) {
                                            final f = snap.data;
                                            if (f == null || !f.existsSync()) {
                                              return Container(
                                                width: 72,
                                                height: 72,
                                                color: Colors.white.withValues(
                                                  alpha: 0.06,
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              );
                                            }
                                            return Image.file(
                                              f,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatDate(e.createdAt),
                                              style:
                                                  MemeopsTextStyles.caption(
                                                    context,
                                                  ).copyWith(
                                                    color: MemeopsColors
                                                        .iosBlueBright,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              e.sourceLabel,
                                              style:
                                                  MemeopsTextStyles.caption(
                                                    context,
                                                  ).copyWith(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                  ),
                                            ),
                                            if (e.caption != null &&
                                                e.caption!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                e.caption!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    MemeopsTextStyles.caption(
                                                      context,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}
