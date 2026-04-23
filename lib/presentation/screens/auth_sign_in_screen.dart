import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kullanıcı adı + şifre (Supabase `signInWithPassword` için arka planda `kullanici@memeops.local`).
/// Kurulum: env.sample — Dashboard’da aynı kullanıcı adıyla eşleşen hesap.
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

  /// Sadece kullanıcı adı; Supabase tarafında `admin` → `admin@memeops.local` eşlenir.
  String _supabaseEmailFromUsername() {
    final raw = _user.text.trim();
    if (raw.isEmpty) return '';
    return '$raw@memeops.local';
  }

  String _mapAuthError(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') ||
        m.contains('invalid_credentials') ||
        m.contains('invalid credential')) {
      return 'Bu kullanıcı Supabase’te yok veya şifre uyuşmuyor. '
          'Alttaki «İlk kurulum: kayıt oluştur» ile dene, ya da Dashboard’da '
          'Authentication → Users ile kullanıcı ekle.';
    }
    if (m.contains('already registered') || m.contains('user already')) {
      return 'Bu kullanıcı zaten var. Doğrudan «Giriş yap» kullan.';
    }
    return e.message;
  }

  Future<void> _signIn() async {
    final raw = _user.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = 'Kullanıcı adını girin.');
      return;
    }
    if (raw.contains('@')) {
      setState(() => _err = 'Sadece kullanıcı adı yazın (@ ve e-posta yok).');
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
      setState(() => _err = _mapAuthError(e));
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Supabase’te henüz kullanıcı yoksa: aynı kullanıcı adı + şifre ile kayıt (anon key ile).
  Future<void> _signUpDemo() async {
    final raw = _user.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = 'Kullanıcı adını girin.');
      return;
    }
    if (raw.contains('@')) {
      setState(() => _err = 'Sadece kullanıcı adı yazın (@ ve e-posta yok).');
      return;
    }
    final pass = _pass.text;
    if (pass.length < 6) {
      setState(() => _err = 'Şifre en az 6 karakter olsun (örn. 12345678).');
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
        // Oturum açıldı (çoğu projede «e-postayı doğrula» kapalıysa).
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayıt oluşturuldu. Giriş olmadıysa: Supabase → Authentication → '
            'Providers → «Confirm email» kapatıp tekrar dene, veya e-postadaki linke tıkla.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _err = _mapAuthError(e));
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
    return Scaffold(
      appBar: AppBar(title: const Text('MemeOps giriş')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Kullanıcı adı: admin · Şifre: 12345678 (örnek). '
            '«Giriş» hata verirse önce «İlk kurulum: kayıt oluştur»a bas — '
            'Supabase’te hesap yoksa böyle oluşur. Geliştirme için Dashboard’da '
            'Authentication → «Confirm email» kapalı olsun.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _err!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextField(
            controller: _user,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Kullanıcı adı',
              hintText: 'admin',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!_loading) _signIn();
            },
            decoration: const InputDecoration(
              labelText: 'Şifre',
              hintText: '12345678',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _signIn,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Giriş yap'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : _signUpDemo,
            child: const Text('İlk kurulum: kayıt oluştur (admin + şifre)'),
          ),
        ],
      ),
    );
  }
}
