import 'package:flutter_test/flutter_test.dart';
import 'package:recify/core/utils/wallet_delta.dart';

void main() {
  group('deltaFor', () {
    test('expense mengurangi saldo', () {
      expect(WalletDelta.deltaFor('EXPENSE', 50000), -50000);
    });

    test('income menambah saldo', () {
      expect(WalletDelta.deltaFor('INCOME', 50000), 50000);
    });

    test('transfer tidak mengubah saldo', () {
      expect(WalletDelta.deltaFor('TRANSFER', 50000), 0.0);
    });

    test('tipe tak dikenal dianggap nol, bukan crash', () {
      expect(WalletDelta.deltaFor('UNKNOWN', 50000), 0.0);
    });
  });

  group('netForUpdate (edit dalam dompet yang sama)', () {
    test('expense 50rb -> 30rb mengembalikan 20rb', () {
      expect(
        WalletDelta.netForUpdate(
          oldType: 'EXPENSE',
          oldAmount: 50000,
          newType: 'EXPENSE',
          newAmount: 30000,
        ),
        20000,
      );
    });

    test('expense 30rb -> 50rb mengurangi 20rb lagi', () {
      expect(
        WalletDelta.netForUpdate(
          oldType: 'EXPENSE',
          oldAmount: 30000,
          newType: 'EXPENSE',
          newAmount: 50000,
        ),
        -20000,
      );
    });

    test('ganti tipe expense 50rb -> income 30rb = +80rb', () {
      expect(
        WalletDelta.netForUpdate(
          oldType: 'EXPENSE',
          oldAmount: 50000,
          newType: 'INCOME',
          newAmount: 30000,
        ),
        80000,
      );
    });

    test('tidak ada perubahan => nol', () {
      expect(
        WalletDelta.netForUpdate(
          oldType: 'INCOME',
          oldAmount: 100000,
          newType: 'INCOME',
          newAmount: 100000,
        ),
        0.0,
      );
    });
  });
}
