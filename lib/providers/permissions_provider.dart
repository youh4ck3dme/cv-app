import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/ai_service.dart';

/// 🔒 State representation for the Hybrid Permission Model
class PermissionsState {
  final bool canGenerateCV;
  final bool canExportPDF;
  final bool isPremium;
  final bool isLoading;
  final String? lastUpdated;
  final String? expiresAt;
  final bool upgradeRequired;

  PermissionsState({
    required this.canGenerateCV,
    required this.canExportPDF,
    required this.isPremium,
    this.isLoading = false,
    this.lastUpdated,
    this.expiresAt,
    this.upgradeRequired = false,
  });

  PermissionsState copyWith({
    bool? canGenerateCV,
    bool? canExportPDF,
    bool? isPremium,
    bool? isLoading,
    String? lastUpdated,
    String? expiresAt,
    bool? upgradeRequired,
  }) {
    return PermissionsState(
      canGenerateCV: canGenerateCV ?? this.canGenerateCV,
      canExportPDF: canExportPDF ?? this.canExportPDF,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expiresAt: expiresAt ?? this.expiresAt,
      upgradeRequired: upgradeRequired ?? this.upgradeRequired,
    );
  }
}

/// 🧠 Managing permissions using local secure cache and async background validation
class PermissionsNotifier extends StateNotifier<PermissionsState> {
  static const _storage = FlutterSecureStorage();
  static const _ed25519PublicKeyHex =
      '80414f167a02fadfcc95133478f7a478224f46a0ac4d7ed0321cc957682191f6';

  PermissionsNotifier({bool autoInit = true})
      : super(PermissionsState(
          canGenerateCV: true,
          canExportPDF: false,
          isPremium: false,
          isLoading: false,
        )) {
    if (autoInit) {
      init();
    }
  }

  /// Verifies asymmetric Ed25519 signature for integrity verification
  Future<bool> _verifySignature(bool canGen, bool canExp, bool isPrem,
      String? expiresAt, String? signatureHex) async {
    if (signatureHex == null) return false;
    try {
      final expiresVal = expiresAt == null ? 'null' : '"$expiresAt"';
      final message =
          '{"canGenerateCV":$canGen,"canExportPDF":$canExp,"isPremium":$isPrem,"expiresAt":$expiresVal}';

      final algorithm = Ed25519();
      final signatureBytes = _hexToBytes(signatureHex);
      final publicKeyBytes = _hexToBytes(_ed25519PublicKeyHex);

      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final signature = Signature(
        signatureBytes,
        publicKey: publicKey,
      );

      return await algorithm.verify(
        utf8.encode(message),
        signature: signature,
      );
    } catch (_) {
      return false;
    }
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  Future<void> init() async {
    // 1. Instantly restore cached permissions for zero-lag and offline startup
    try {
      final storedGenRaw = await _storage.read(key: 'cached_canGenerateCV');
      final canGenerateVal =
          storedGenRaw != null ? (storedGenRaw == 'true') : true;

      final canExportVal =
          await _storage.read(key: 'cached_canExportPDF') == 'true';
      final isPremiumVal =
          await _storage.read(key: 'cached_isPremium') == 'true';
      final lastUpd = await _storage.read(key: 'cached_lastUpdated');
      final expiresAtVal = await _storage.read(key: 'cached_expiresAt');
      final cachedSig = await _storage.read(key: 'cached_signature');

      bool isSignatureValid = false;
      if (cachedSig != null) {
        isSignatureValid = await _verifySignature(canGenerateVal, canExportVal,
            isPremiumVal, expiresAtVal, cachedSig);
      }

      bool isExpired = false;
      if (expiresAtVal != null) {
        try {
          final expirationDate = DateTime.parse(expiresAtVal);
          if (DateTime.now().isAfter(expirationDate)) {
            isExpired = true;
          }
        } catch (_) {
          isExpired = true;
        }
      }

      if (!isSignatureValid || isExpired) {
        // Cache has been tampered with or subscription has expired! Invalidate cache.
        await _storage.delete(key: 'cached_canGenerateCV');
        await _storage.delete(key: 'cached_canExportPDF');
        await _storage.delete(key: 'cached_isPremium');
        await _storage.delete(key: 'cached_lastUpdated');
        await _storage.delete(key: 'cached_expiresAt');
        await _storage.delete(key: 'cached_signature');

        state = PermissionsState(
          canGenerateCV: true,
          canExportPDF: false,
          isPremium: false,
          lastUpdated: null,
          expiresAt: null,
          isLoading: false,
        );
      } else {
        state = PermissionsState(
          canGenerateCV: canGenerateVal,
          canExportPDF: canExportVal,
          isPremium: isPremiumVal,
          lastUpdated: lastUpd,
          expiresAt: expiresAtVal,
          isLoading: false,
        );
      }
    } catch (_) {
      // Fail silently and keep defaults
    }

    // 2. Perform a background authority validation check asynchronously
    refreshPermissions();
  }

  /// Queries backend to validate subscription and custom key validity
  Future<void> refreshPermissions() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      String? appUserId;
      try {
        appUserId = await Purchases.appUserID;
      } catch (_) {}

      final useCustom = await _storage.read(key: 'useCustomKey') == 'true';
      final customKey = await _storage.read(key: 'customApiKey');

      final perms = await AiGateway.checkPermissions(
        appUserId: appUserId,
        customApiKey: useCustom ? customKey : null,
      );

      if (perms['upgradeRequired'] == true) {
        state = state.copyWith(
          upgradeRequired: true,
          canGenerateCV: false,
          canExportPDF: false,
          isPremium: false,
          isLoading: false,
        );
        return;
      }

      final newCanGenerate = perms['canGenerateCV'] == true;
      final newCanExport = perms['canExportPDF'] == true;
      final newIsPremium = perms['isPremium'] == true;
      final newExpiresAt = perms['expiresAt'] as String?;
      final serverSignature = perms['signature'] as String?;
      final nowTimestamp = DateTime.now().toIso8601String();

      // Verify server signature before trusting it
      bool isSigValid = false;
      if (serverSignature != null) {
        isSigValid = await _verifySignature(newCanGenerate, newCanExport,
            newIsPremium, newExpiresAt, serverSignature);
      }

      if (!isSigValid) {
        // Log or handle signature mismatch: downgrade to default non-premium state to prevent MITM bypass
        state = state.copyWith(
          canGenerateCV: true,
          canExportPDF: false,
          isPremium: false,
          expiresAt: null,
          isLoading: false,
          upgradeRequired: false,
        );
        return;
      }

      // Check for expiration
      bool isExpired = false;
      if (newExpiresAt != null) {
        try {
          final expirationDate = DateTime.parse(newExpiresAt);
          if (DateTime.now().isAfter(expirationDate)) {
            isExpired = true;
          }
        } catch (_) {
          isExpired = true;
        }
      }

      final finalCanExport = isExpired ? false : newCanExport;
      final finalIsPremium = isExpired ? false : newIsPremium;

      // Write parameters to local cache for offline-safe fallback access
      await _storage.write(
          key: 'cached_canGenerateCV', value: newCanGenerate.toString());
      await _storage.write(
          key: 'cached_canExportPDF', value: finalCanExport.toString());
      await _storage.write(
          key: 'cached_isPremium', value: finalIsPremium.toString());
      await _storage.write(key: 'cached_lastUpdated', value: nowTimestamp);
      if (newExpiresAt != null) {
        await _storage.write(key: 'cached_expiresAt', value: newExpiresAt);
      } else {
        await _storage.delete(key: 'cached_expiresAt');
      }
      await _storage.write(key: 'cached_signature', value: serverSignature);

      state = PermissionsState(
        canGenerateCV: newCanGenerate,
        canExportPDF: finalCanExport,
        isPremium: finalIsPremium,
        lastUpdated: nowTimestamp,
        expiresAt: newExpiresAt,
        isLoading: false,
        upgradeRequired: false,
      );
    } catch (e) {
      // 🛡️ Safe fallback: retain the last known cached states if network is down
      // Check if current cached state is expired before keeping it
      bool isExpired = false;
      final currentExpiresAt = state.expiresAt;
      if (currentExpiresAt != null) {
        try {
          final expirationDate = DateTime.parse(currentExpiresAt);
          if (DateTime.now().isAfter(expirationDate)) {
            isExpired = true;
          }
        } catch (_) {
          isExpired = true;
        }
      }

      if (isExpired) {
        state = state.copyWith(
          canExportPDF: false,
          isPremium: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

/// Global provider for application permissions
final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});
