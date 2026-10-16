import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/utils/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hash deterministik untuk salt yang sama', () {
      expect(PasswordHasher.hash('rahasia123', 'salt-abc'),
          PasswordHasher.hash('rahasia123', 'salt-abc'));
    });

    test('salt berbeda menghasilkan hash berbeda', () {
      final h1 = PasswordHasher.hash('rahasia123', PasswordHasher.newSalt());
      final h2 = PasswordHasher.hash('rahasia123', PasswordHasher.newSalt());
      expect(h1, isNot(equals(h2)));
    });

    test('verify true untuk password benar, false untuk salah', () {
      const salt = 'salt-uji';
      final hash = PasswordHasher.hash('katasandi', salt);
      expect(PasswordHasher.verify('katasandi', salt, hash), isTrue);
      expect(PasswordHasher.verify('salah', salt, hash), isFalse);
      expect(PasswordHasher.verify('katasandi', 'salt-lain', hash), isFalse);
    });

    test('verify menolak panjang hash berbeda tanpa bocor', () {
      expect(PasswordHasher.verify('x', 's', 'pendek'), isFalse);
    });

    test('normalizeEmail memangkas & mengecilkan huruf', () {
      expect(PasswordHasher.normalizeEmail('  User@Contoh.COM  '),
          'user@contoh.com');
    });
  });
}
