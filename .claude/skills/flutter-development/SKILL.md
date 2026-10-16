---
name: flutter-development
description: >
  Flutter development pitfalls & rules project ini (Recify). Use when
  editing TextField/InputDecoration, styling widgets from theme, or when
  UI shows unexpected inherited styling (double border, wrong colors,
  theme override not applied).
---

# Flutter Development Rules

Pitfall yang pernah terjadi di project ini — cek daftar ini SEBELUM
menulis/mereview kode UI Flutter.

## 1. Double border pada TextField (JANGAN ulangi)

### Gejala
Field teks tampak punya dua border: container luar (decoration custom)
+ kotak outline tambahan DI DALAM yang membungkus placeholder/teks.
Tampak "kaku".

### Penyebab
Tema global `inputDecorationTheme` di `lib/core/theme/app_theme.dart`
men-set `enabledBorder` + `focusedBorder` berupa `OutlineInputBorder`.
Di Material 3, **`enabledBorder` menang atas `border`** — jadi
`border: InputBorder.none` saja TIDAK cukup untuk menghilangkan outline.

### Aturan
Setiap `TextField` yang dibungkus `Container`/`DecoratedBox` punya
border sendiri, wajib override ketiganya:

```dart
decoration: InputDecoration(
  hintText: hint,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
),
```

Contoh benar sudah ada di:
- `lib/presentation/screens/login_screen.dart` (field widget)
- `lib/presentation/screens/signup_screen.dart` (`_SignUpField`)
- `lib/presentation/screens/manual_transaction_screen.dart:220-222`

### Saat review
Kalau diff menambah `TextField` baru: cek apakah dibungkus container
ber-border. Jika ya, pastikan ketiga border InputBorder.none ikut ditulis.
Jangan ubah tema global untuk memperbaiki satu layar — layar lain
(mis. settings) sengaja memakai OutlineInputBorder bawaan tema.
