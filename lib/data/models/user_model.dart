/// Akun lokal aplikasi. Satu baris = satu ruang data terpisah
/// (dompet, kategori, transaksi, budget difilter per `id`).
class UserModel {
  final String id;
  final String email;
  final String passwordHash;
  final String salt;
  final String name;
  final String? avatarPath;

  /// true kalau akun ini sudah pernah login manual di perangkat —
  /// syarat pindah akun langsung tanpa password di switcher.
  final bool hasLoggedIn;
  final int createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.name,
    this.avatarPath,
    this.hasLoggedIn = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'name': name,
        'avatar_path': avatarPath,
        'has_logged_in': hasLoggedIn ? 1 : 0,
        'created_at': createdAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        salt: map['salt'] as String,
        name: (map['name'] as String?) ?? '',
        avatarPath: map['avatar_path'] as String?,
        hasLoggedIn: (map['has_logged_in'] as int? ?? 0) == 1,
        createdAt:
            map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );

  UserModel copyWith({String? name, String? avatarPath, bool? hasLoggedIn}) =>
      UserModel(
        id: id,
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        name: name ?? this.name,
        avatarPath: avatarPath ?? this.avatarPath,
        hasLoggedIn: hasLoggedIn ?? this.hasLoggedIn,
        createdAt: createdAt,
      );
}
