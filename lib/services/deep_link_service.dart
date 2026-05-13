import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens for incoming deep links and handles Supabase auth callbacks.
///
/// Usage:
///   final service = DeepLinkService();
///   service.initialize(onAuthenticated: () => goToHome());
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Callbacks set by the caller
  VoidCallback? _onAuthenticated;
  VoidCallback? _onVerificationFailed;

  /// Call once from main.dart or your root widget's initState.
  ///
  /// [onAuthenticated]    — called when the user's session is confirmed
  /// [onVerificationFailed] — called when the link is invalid or expired
  Future<void> initialize({
    required VoidCallback onAuthenticated,
    VoidCallback? onVerificationFailed,
  }) async {
    _onAuthenticated = onAuthenticated;
    _onVerificationFailed = onVerificationFailed;

    // 1️⃣ Handle the link that LAUNCHED the app (cold start)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('[DeepLinkService] Cold-start URI: $initialUri');
      await _handleUri(initialUri);
    }

    // 2️⃣ Handle links while the app is already running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) async {
        debugPrint('[DeepLinkService] Warm-start URI: $uri');
        await _handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DeepLinkService] Stream error: $err');
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    debugPrint('[DeepLinkService] Handling URI: $uri');

    // Only handle our scheme
    if (uri.scheme != 'grocerease') return;

    // Supabase appends the token as a fragment: grocerease://login-callback#access_token=...
    // OR as query params depending on the flow.
    // We extract it and let the Supabase SDK handle session creation.
    final fragment = uri.fragment;
    final query = uri.query;

    // Build a pseudo-URL the Supabase SDK can parse
    final rawUrl = fragment.isNotEmpty
        ? 'http://localhost/#$fragment'   // PKCE / implicit flow fragment
        : 'http://localhost/?$query';     // Magic link / OTP query params

    try {
      final response =
      await Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(rawUrl));

      if (response.session != null) {
        debugPrint('[DeepLinkService] ✅ Session established: ${response.session!.user.email}');
        _onAuthenticated?.call();
      } else {
        debugPrint('[DeepLinkService] ⚠️ No session in response');
        _onVerificationFailed?.call();
      }
    } on AuthException catch (e) {
      debugPrint('[DeepLinkService] ❌ AuthException: ${e.message}');
      _onVerificationFailed?.call();
    } catch (e) {
      debugPrint('[DeepLinkService] ❌ Unexpected error: $e');
      _onVerificationFailed?.call();
    }
  }

  /// Cancel the stream subscription — call from dispose() if needed.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}