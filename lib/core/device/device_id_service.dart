import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Provides a stable, privacy-friendly per-install identifier used as
/// `device_id_hash` for guest quota accounting on the backend.
///
/// The id is a random 128-bit hex string generated on first use and persisted
/// locally; it is not derived from any hardware identifier. Without a stable
/// per-device id, all guest users collapse into a single shared daily quota
/// bucket on the backend, which makes conversions fail for everyone once a
/// few conversions were consumed that day.
class DeviceIdService {
  static const String _prefsKey = 'pdfword_device_id_hash';

  String? _cached;

  Future<String> getId() async {
    final cached = _cached;
    if (cached != null && cached.isNotEmpty) return cached;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey)?.trim() ?? '';
    if (existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final generated = _generate();
    await prefs.setString(_prefsKey, generated);
    _cached = generated;
    return generated;
  }

  String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
