import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/language_picker_sheet.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_night_backdrop.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kullanıcı adı + şifre (Supabase `signInWithPassword` için arka planda `kullanici@memeops.local`).
class AuthSignInScreen extends StatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  State<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends State<AuthSignInScreen> {
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController();
  bool _loading = false;
  String? _err;

  String _supabaseEmailFromUsername() {
    final raw = _user.text.trim();
    if (raw.isEmpty) return '';
    return '$raw@memeops.local';
  }

  String _mapAuthError(AppLocalizations l10n, AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') ||
        m.contains('invalid_credentials') ||
        m.contains('invalid credential')) {
      return l10n.authErrInvalidLogin;
    }
    if (m.contains('already registered') || m.contains('user already')) {
      return l10n.authErrAlreadyRegistered;
    }
    return e.message;
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    final raw = _user.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = l10n.authErrEmptyUser);
      return;
    }
    if (raw.contains('@')) {
      setState(() => _err = l10n.authErrNoAt);
      return;
    }
    final email = _supabaseEmailFromUsername();
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _pass.text,
      );
    } on AuthException catch (e) {
      setState(() => _err = _mapAuthError(l10n, e));
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signUpDemo() async {
    final l10n = AppLocalizations.of(context);
    final raw = _user.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = l10n.authErrEmptyUser);
      return;
    }
    if (raw.contains('@')) {
      setState(() => _err = l10n.authErrNoAt);
      return;
    }
    final pass = _pass.text;
    if (pass.length < 6) {
      setState(() => _err = l10n.authErrPasswordShort);
      return;
    }
    final email = _supabaseEmailFromUsername();
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: pass,
      );
      if (!mounted) return;
      if (res.session != null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.authSnackSignUp),
          backgroundColor: MemeopsColors.surfaceCharcoal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _err = _mapAuthError(l10n, e));
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MemeopsNightBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.languageTitle,
                  onPressed: () => showMemeopsLanguageSheet(context),
                  icon: Icon(
                    Icons.language_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MemeopsRadii.md),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    color: Colors.white.withValues(alpha: 0.07),
                    boxShadow: [
                      BoxShadow(
                        color: MemeopsColors.iosBlue.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 38,
                    color: MemeopsColors.iosBlueBright,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: MemeopsTextStyles.displayTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.authTagline,
                textAlign: TextAlign.center,
                style: MemeopsTextStyles.subtitle(context),
              ),
              const SizedBox(height: 28),
              MemeopsGlassSurface(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authSignInTitle,
                      style: MemeopsTextStyles.sectionTitle(context),
                    ),
                    const SizedBox(height: 18),
                    if (_err != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(MemeopsRadii.sm),
                        ),
                        child: Text(
                          _err!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    TextField(
                      controller: _user,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: l10n.authUsername,
                        hintText: l10n.authUsernameHint,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (!_loading) _signIn();
                      },
                      decoration: InputDecoration(
                        labelText: l10n.authPassword,
                        hintText: l10n.authPasswordHint,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.authSignIn),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _loading ? null : _signUpDemo,
                      child: Text(l10n.authSignUp),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MemeopsGlassSurface(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                borderRadius: MemeopsRadii.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: MemeopsColors.iosBlue.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(MemeopsRadii.sm),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: MemeopsColors.iosBlueBright,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.authBenefitTitle,
                            style: MemeopsTextStyles.sectionTitle(context).copyWith(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _benefitRow(context, Icons.link_rounded, l10n.authBenefitTelegram),
                    _benefitRow(context, Icons.work_outline_rounded, l10n.authBenefitProfession),
                    _benefitRow(context, Icons.image_rounded, l10n.authBenefitImage),
                    _benefitRow(context, Icons.cloud_done_rounded, l10n.authBenefitSupabase),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: MemeopsColors.iosBlueBright),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: MemeopsTextStyles.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
