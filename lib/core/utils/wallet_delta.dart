/// Matematika saldo dompet, murni tanpa Flutter/DB agar bisa diuji cepat.
///
/// Aturan: EXPENSE mengurangi, INCOME menambah, TRANSFER (dan tipe tak
/// dikenal) nol. Saldo boleh mencapai 0 atau negatif — tidak ada clamp —
/// supaya user bisa isi ulang saat ada income baru.
class WalletDelta {
  /// Dampak satu transaksi terhadap `current_balance`.
  static double deltaFor(String type, double amount) => switch (type) {
        'EXPENSE' => -amount,
        'INCOME' => amount,
        _ => 0.0,
      };

  /// Dampak bersih saat transaksi diedit dalam dompet yang SAMA:
  /// balikkan delta lama, lalu terapkan delta baru.
  /// (Pindah dompet ditangani terpisah: reverse di dompet lama,
  /// apply [deltaFor] di dompet baru.)
  static double netForUpdate({
    required String oldType,
    required double oldAmount,
    required String newType,
    required double newAmount,
  }) =>
      deltaFor(newType, newAmount) - deltaFor(oldType, oldAmount);
}
