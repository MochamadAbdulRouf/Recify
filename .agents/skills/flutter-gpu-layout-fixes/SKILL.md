---
name: flutter-gpu-layout-fixes
description: >
  Fix GPU rendering artifacts (red band from BackdropFilter on Mali GPUs) and
  layout overflow errors on positioned widgets like chart tooltips in Flutter.
  Use this skill when encountering solid color bands on glass/blur panels or
  "overflowed by N pixels" errors on Positioned children.
---

# Flutter GPU Artifact & Layout Overflow Fixes

## When to Use This Skill

- **Solid red/green/black band** appears over a `BackdropFilter` or glass panel — especially on **Mali GPU** devices (Infinix, Samsung Exynos, Mediatek chipsets)
- **"Right/Left overflowed by N pixels"** error on `Positioned` widgets inside a `Stack` (e.g., chart tooltips, floating labels)
- **`margin.isNonNegative` assertion** error when using negative `EdgeInsets` on a `Container`

---

## Bug 1: Red Band GPU Artifact on BackdropFilter

### Error yang Muncul

Tidak ada error message di console — hanya visual. Sebuah **kotak/band merah solid** menutupi sebagian atau seluruh panel glass yang menggunakan `BackdropFilter`. Hanya muncul di device Android tertentu dengan **GPU Mali** (Infinix, Mediatek, beberapa Samsung Exynos).

Screenshot contoh: Band merah menutupi hero card nominal di menu Statistik.

### Root Cause

`BackdropFilter` membaca pixel di belakangnya untuk menerapkan efek blur. Pada GPU Mali, frame pertama bisa **meng-sample memori tile GPU yang belum diinisialisasi** — isinya default berwarna merah solid.

### Percobaan 1 — RepaintBoundary (❌ GAGAL)

```dart
ClipRRect(
  borderRadius: r,
  child: RepaintBoundary(  // ← ditambahkan di dalam ClipRRect
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: DecoratedBox(...),
    ),
  ),
)
```

**Kenapa gagal:** `RepaintBoundary` di dalam `ClipRRect` hanya mengisolasi repaint, tapi BackdropFilter tetap membaca pixel dari layer di bawahnya. Jika belum ada pixel yang valid di-render, hasilnya tetap band merah.

### Solusi Final (✅ BERHASIL)

Dua perubahan kunci:
1. **Pindahkan `RepaintBoundary` ke luar** `ClipRRect` — mengisolasi seluruh panel sebagai satu compositing layer
2. **Tambahkan `ColoredBox` sebagai layer pertama** di dalam `Stack` — memastikan GPU selalu punya pixel data yang valid untuk di-blur

```dart
// ✅ SOLUSI YANG BERHASIL
RepaintBoundary(                              // 1. Di LUAR ClipRRect
  child: ClipRRect(
    borderRadius: r,
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppColors.bgCanvas),  // 2. Base layer solid
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: fill ?? const LinearGradient(
                colors: [AppColors.glassFill, AppColors.glassFill],
              ),
              // JANGAN pakai borderRadius di sini — ClipRRect sudah handle
              border: Border.all(color: borderColor),
            ),
            child: Stack(
              children: [
                // glow blobs, sheen, highlight, content...
              ],
            ),
          ),
        ),
      ],
    ),
  ),
)
```

### Kenapa Berhasil

| Komponen | Fungsi |
|---|---|
| `RepaintBoundary` di luar | Mengisolasi seluruh panel sebagai compositing layer tersendiri |
| `ColoredBox` sebagai child pertama Stack | GPU Mali selalu punya pixel valid (warna canvas gelap) untuk di-sample oleh blur |
| Hapus `borderRadius` dari `DecoratedBox` | `ClipRRect` sudah handle clipping, tidak perlu double-clip |

### File yang Diubah

- [`glass_panel.dart`](file:///d:/Coding/Recify/lib/presentation/components/glass_panel.dart) — Widget `GlassPanel`, method `build()`

---

## Bug 2: Negative Margin Assertion Error

### Error yang Muncul

```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════
The following assertion was thrown building _ChartTooltip(dirty):
'package:flutter/src/widgets/container.dart': Failed assertion: line 271 pos 15:
'margin == null || margin.isNonNegative': is not true.
```

App crash saat membuild widget `_ChartTooltip`. Error terjadi di caret (segitiga kecil) tooltip chart.

### Root Cause

Flutter `Container` widget **tidak mengizinkan margin negatif**. Ada assertion eksplisit di `container.dart` line 271. Kode asli menggunakan `margin: EdgeInsets.only(top: -1)` untuk menggeser caret tooltip supaya overlap sedikit dengan bubble-nya.

### Kode yang Error (❌)

```dart
Transform.rotate(
  angle: 0.785398, // 45°
  child: Container(
    width: 8,
    height: 8,
    margin: const EdgeInsets.only(top: -1),  // ❌ CRASH! Margin negatif
    decoration: BoxDecoration(
      color: AppColors.glassTooltip,
      border: Border.all(color: AppColors.borderMedium),
    ),
  ),
)
```

### Solusi Final (✅ BERHASIL)

Ganti `margin` negatif dengan `Transform.translate` yang menggeser visual widget tanpa constraint:

```dart
// ✅ SOLUSI YANG BERHASIL
Transform.translate(
  offset: const Offset(0, -1),  // Geser 1px ke atas — sama efeknya
  child: Transform.rotate(
    angle: 0.785398, // 45°
    child: Container(
      width: 8,
      height: 8,
      // Tidak ada margin
      decoration: BoxDecoration(
        color: AppColors.glassTooltip,
        border: Border.all(color: AppColors.borderMedium),
      ),
    ),
  ),
)
```

### Kenapa Berhasil

`Transform.translate` menggeser posisi render widget secara visual tanpa mengubah layout constraints. Tidak ada assertion yang dilanggar karena kita tidak menggunakan `margin` sama sekali.

### File yang Diubah

- [`analytics_screen.dart`](file:///d:/Coding/Recify/lib/presentation/screens/analytics_screen.dart) — Widget `_ChartTooltip`, method `build()`

---

## Bug 3: Layout Overflow pada Chart Tooltip

### Error yang Muncul

Garis kuning-hitam di samping chart dengan teks:
```
A RenderFlex overflowed by 6.5 pixels on the right.
```

Muncul saat tap bar chart di hari yang ada di pinggir (Senin atau Minggu), karena tooltip melebar melewati batas parent.

### Root Cause

Tooltip di-posisikan dengan `left: -28, right: -28` agar bisa lebih lebar dari bar-nya. Tapi ini membuat widget melebar melewati batas `Stack` parent, memicu overflow warning.

### Percobaan 1 — Negative left/right (❌ GAGAL — overflow 6.5px)

```dart
Positioned(
  bottom: barHeight + 8,
  left: -28,     // ❌ Overflow di bar paling kiri
  right: -28,    // ❌ Overflow di bar paling kanan
  child: Center(
    child: _ChartTooltip(label: amount),
  ),
)
```

**Error:** `Right overflowed by 6.5 pixels`

### Percobaan 2 — OverflowBox (❌ GAGAL — infinite size crash)

```dart
Positioned(
  bottom: barHeight + 8,
  left: 0,
  right: 0,
  child: OverflowBox(
    maxWidth: 200,  // ❌ CRASH!
    child: _ChartTooltip(label: amount),
  ),
)
```

**Error:** `RenderConstrainedOverflowBox object was given an infinite size during layout.` dan `RRect argument contained a NaN value.`

**Kenapa gagal:** `OverflowBox` di dalam `Positioned` dengan `left: 0, right: 0` mendapat constrained width tapi kemudian height menjadi infinite karena `Positioned` tidak membatasi height.

### Percobaan 3 — UnconstrainedBox (❌ GAGAL — overflow 31px kedua sisi)

```dart
Positioned(
  bottom: barHeight + 8,
  left: 0,
  right: 0,
  child: UnconstrainedBox(
    clipBehavior: Clip.none,
    child: _ChartTooltip(label: amount),
  ),
)
```

**Error:** `Right overflowed by 31 pixels` DAN `Left overflowed by 31 pixels`

**Kenapa gagal:** `UnconstrainedBox` membolehkan child sizing sendiri, tapi widget ini sendiri tetap **melaporkan overflow** ketika child-nya lebih besar dari constraints yang diterima. `clipBehavior: Clip.none` hanya mencegah clipping visual, tidak mencegah error reporting.

### Solusi Final (✅ BERHASIL)

Hapus `left` dan `right` sepenuhnya dari `Positioned`. Biarkan Stack alignment yang handle centering:

```dart
// ✅ SOLUSI YANG BERHASIL
Stack(
  clipBehavior: Clip.none,                  // Izinkan overflow visual
  alignment: Alignment.bottomCenter,        // Center horizontal otomatis
  children: [
    // ... bar widget ...
    if (isActive && activeSpendAmount > 0)
      Positioned(
        bottom: barHeight + 8,
        // TIDAK ADA left/right — kunci utamanya di sini
        child: _ChartTooltip(
          label: CurrencyFormatter.formatRupiah(activeSpendAmount),
        ),
      ),
  ],
)
```

### Kenapa Berhasil

| Aspek | Perilaku |
|---|---|
| **Tidak ada `left`/`right`** | `Positioned` tidak memaksa horizontal constraint → child sizing intrinsik (sesuai konten) |
| **Stack `alignment: bottomCenter`** | Widget yang tidak di-constrain oleh `Positioned` otomatis diposisikan di tengah horizontal |
| **`clipBehavior: Clip.none`** | Tooltip bisa render melewati batas Stack secara visual tanpa error |
| **Tidak perlu wrapper** | Tidak perlu `OverflowBox`, `UnconstrainedBox`, atau `Center` — lebih simpel, tidak crash |

### File yang Diubah

- [`analytics_screen.dart`](file:///d:/Coding/Recify/lib/presentation/screens/analytics_screen.dart) — Bar chart section di `_AnalyticsScreenState.build()`, sekitar line 244-252

---

## Quick Reference Checklist

Saat menemukan rendering bug di device Android:

- [ ] **Band merah/warna solid di blur?** → Tambahkan `ColoredBox` base layer sebelum `BackdropFilter`
- [ ] **Margin negatif crash?** → Ganti dengan `Transform.translate(offset: Offset(dx, dy))`
- [ ] **Overflow di tooltip/label?** → Hapus `left`/`right` dari `Positioned`, andalkan Stack alignment
- [ ] **Test di device Mali GPU** → Infinix, beberapa Samsung, device Mediatek
- [ ] **Test edge case** → Tap bar pertama dan terakhir di chart untuk verifikasi tidak ada overflow

---

## Ringkasan Semua Fix

| Bug | Error Message | Fix |
|---|---|---|
| Band merah GPU | _(visual only, no console error)_ | `ColoredBox` + `RepaintBoundary` di luar `ClipRRect` |
| Margin negatif | `margin.isNonNegative is not true` | `Transform.translate(offset: Offset(0, -1))` |
| Tooltip overflow | `overflowed by N pixels` | Hapus `left`/`right` dari `Positioned` |
