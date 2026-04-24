import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/screens/meme_archive_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/profession_flow_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/telegram_analysis_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/telegram_flow_screen.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/language_picker_sheet.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_floating_tab_bar.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_night_backdrop.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Start on Telegram link flow (primary first-use path).
  int _index = 1;

  String _displayName(AppLocalizations l10n) {
    final e = Supabase.instance.client.auth.currentUser?.email;
    if (e == null || e.isEmpty) return l10n.defaultDisplayName;
    final local = e.split('@').first;
    return local.length > 18 ? '${local.substring(0, 18)}…' : local;
  }

  Future<void> _backToLogin() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Keep the current session if sign-out fails.
    }
  }

  /// 0: Profesyon — derli toplu selamlama, alt açıklama yok, geri + dil.
  /// 1: Telegram — üst başlık yok (geri kaldırıldı).
  /// 2: Analiz, 3: Arşiv — mevcut davranış.
  Widget _headerTopContent(AppLocalizations l10n) {
    if (_index == 2) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tabAnalysis,
              style: MemeopsTextStyles.displayTitle(
                context,
              ).copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                l10n.analysisMyPublications,
                style: MemeopsTextStyles.caption(context).copyWith(
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_index == 3) {
      return Row(
        children: [
          _HeaderActionButton(
            tooltip: l10n.backToLogin,
            onPressed: _backToLogin,
            icon: Icons.arrow_back_rounded,
          ),
          const Spacer(),
          _HeaderActionButton(
            tooltip: l10n.languageTitle,
            onPressed: () => showMemeopsLanguageSheet(context),
            icon: Icons.language_rounded,
          ),
        ],
      );
    }
    if (_index == 1) {
      // Telegram sekmesi: üstte geri yok (yalnızca link alanı).
      return const SizedBox.shrink();
    }
    // _index == 0: Meslek
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HeaderActionButton(
          tooltip: l10n.backToLogin,
          onPressed: _backToLogin,
          icon: Icons.arrow_back_rounded,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.greeting(_displayName(l10n)),
            style: MemeopsTextStyles.sectionTitle(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          tooltip: l10n.languageTitle,
          onPressed: () => showMemeopsLanguageSheet(context),
          icon: Icons.language_rounded,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: MemeopsColors.bgBottom,
      body: MemeopsNightBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  _index == 1 ? 4 : 8,
                  20,
                  _index == 1 ? 4 : 6,
                ),
                child: _headerTopContent(l10n),
              ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    ProfessionFlowScreen(),
                    TelegramFlowScreen(),
                    TelegramAnalysisScreen(),
                    MemeArchiveScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: MemeopsColors.bgBottom,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          minimum: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: MemeopsFloatingTabBar(
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            items: [
              MemeopsFloatingTabItem(
                icon: Icons.work_outline_rounded,
                selectedIcon: Icons.work_rounded,
                label: l10n.tabProfession,
              ),
              MemeopsFloatingTabItem(
                icon: Icons.link_outlined,
                selectedIcon: Icons.link_rounded,
                label: l10n.tabTelegram,
              ),
              MemeopsFloatingTabItem(
                icon: Icons.analytics_outlined,
                selectedIcon: Icons.analytics_rounded,
                label: l10n.tabAnalysis,
              ),
              MemeopsFloatingTabItem(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library_rounded,
                label: l10n.tabArchive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            onPressed: onPressed,
            splashRadius: 24,
            icon: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.88),
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}
