import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Hash password untuk akun lokal. Murni Dart agar bisa diuji cepat.
///
/// Format: SHA-256(salt + password), salt acak 16 byte (base64).
/// Tidak ada server, tidak ada verifikasi email — hash hanya mencegah
/// password terbaca polos dari file database di perangkat.
class PasswordHasher {
  static final _random = Random.secure();

  /// Salt acak baru untuk tiap akun.
  static String newSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash heksadesimal dari kombinasi salt + password.
  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  /// true kalau [password] cocok dengan pasangan hash/salt tersimpan.
  /// Perbandingan waktu-konstan sederhana agar tak bocor lewat timing.
  static bool verify(String password, String salt, String expectedHash) {
    final actual = hash(password, salt);
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Normalisasi email untuk penyimpanan & pencarian (unik case-insensitive).
  static String normalizeEmail(String email) => email.trim().toLowerCase();
}
