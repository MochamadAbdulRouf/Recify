---
name: flutter-gpu-layout-fixes-en
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

### Error Encountered

No error message in the console — it's purely visual. A **solid red rectangle/band** covers part or all of a glass panel using `BackdropFilter`. Only appears on certain Android devices with **Mali GPUs** (Infinix, Mediatek, some Samsung Exynos).

Example: A red band covers the hero card nominal on the Statistics screen.

### Root Cause

`BackdropFilter` reads pixels behind it to apply the blur effect. On Mali GPUs, the first frame can **sample uninitialized tile memory** — GPU memory that hasn't been painted yet. The default value of this uninitialized memory renders as a solid red color.

### Attempt 1 — RepaintBoundary (❌ FAILED)

```dart
ClipRRect(
  borderRadius: r,
  child: RepaintBoundary(  // ← added inside ClipRRect
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: DecoratedBox(...),
    ),
  ),
)
```

**Why it failed:** `RepaintBoundary` inside `ClipRRect` only isolates repaints, but `BackdropFilter` still reads pixels from the layer beneath it. If no valid pixels have been rendered yet, the result is still a red band.

### Final Solution (✅ WORKS)

Two key changes:
1. **Move `RepaintBoundary` outside** `ClipRRect` — isolates the entire panel as a single compositing layer
2. **Add a `ColoredBox` as the first layer** inside a `Stack` — ensures the GPU always has valid pixel data to blur

```dart
// ✅ SOLUTION THAT WORKS
RepaintBoundary(                              // 1. OUTSIDE ClipRRect
  child: ClipRRect(
    borderRadius: r,
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppColors.bgCanvas),  // 2. Solid base layer
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: fill ?? const LinearGradient(
                colors: [AppColors.glassFill, AppColors.glassFill],
              ),
              // Do NOT use borderRadius here — ClipRRect already handles it
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

### Why It Works

| Component | Purpose |
|---|---|
| `RepaintBoundary` outside | Isolates the entire panel as its own compositing layer |
| `ColoredBox` as first Stack child | Mali GPU always has valid pixels (dark canvas color) to sample for the blur |
| Remove `borderRadius` from `DecoratedBox` | `ClipRRect` already handles clipping; redundant radius causes double-clip |

### Files Changed

- [`glass_panel.dart`](file:///d:/Coding/Recify/lib/presentation/components/glass_panel.dart) — `GlassPanel` widget, `build()` method

---

## Bug 2: Negative Margin Assertion Error

### Error Encountered

```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════
The following assertion was thrown building _ChartTooltip(dirty):
'package:flutter/src/widgets/container.dart': Failed assertion: line 271 pos 15:
'margin == null || margin.isNonNegative': is not true.
```

App crashes when building the `_ChartTooltip` widget. The error occurs on the caret (small triangle) of the chart tooltip.

### Root Cause

Flutter's `Container` widget **does not allow negative margins**. There's an explicit assertion in `container.dart` line 271. The original code used `margin: EdgeInsets.only(top: -1)` to shift the tooltip caret so it slightly overlaps with the bubble above it.

### Code That Crashes (❌)

```dart
Transform.rotate(
  angle: 0.785398, // 45°
  child: Container(
    width: 8,
    height: 8,
    margin: const EdgeInsets.only(top: -1),  // ❌ CRASH! Negative margin
    decoration: BoxDecoration(
      color: AppColors.glassTooltip,
      border: Border.all(color: AppColors.borderMedium),
    ),
  ),
)
```

### Final Solution (✅ WORKS)

Replace the negative `margin` with `Transform.translate` which shifts the widget visually without affecting layout constraints:

```dart
// ✅ SOLUTION THAT WORKS
Transform.translate(
  offset: const Offset(0, -1),  // Shift 1px upward — same visual effect
  child: Transform.rotate(
    angle: 0.785398, // 45°
    child: Container(
      width: 8,
      height: 8,
      // No margin at all
      decoration: BoxDecoration(
        color: AppColors.glassTooltip,
        border: Border.all(color: AppColors.borderMedium),
      ),
    ),
  ),
)
```

### Why It Works

`Transform.translate` shifts the render position of a widget visually without changing its layout constraints. No assertion is violated because we're not using `margin` at all.

### Files Changed

- [`analytics_screen.dart`](file:///d:/Coding/Recify/lib/presentation/screens/analytics_screen.dart) — `_ChartTooltip` widget, `build()` method

---

## Bug 3: Layout Overflow on Chart Tooltip

### Error Encountered

A yellow-black striped bar appears next to the chart with the text:
```
A RenderFlex overflowed by 6.5 pixels on the right.
```

This appears when tapping a bar chart on an edge day (Monday or Sunday), because the tooltip extends beyond the parent bounds.

### Root Cause

The tooltip was positioned with `left: -28, right: -28` to allow it to be wider than its parent bar. However, this causes the widget to extend beyond the `Stack` parent bounds, triggering overflow warnings.

### Attempt 1 — Negative left/right (❌ FAILED — 6.5px overflow)

```dart
Positioned(
  bottom: barHeight + 8,
  left: -28,     // ❌ Overflow on leftmost bar
  right: -28,    // ❌ Overflow on rightmost bar
  child: Center(
    child: _ChartTooltip(label: amount),
  ),
)
```

**Error:** `Right overflowed by 6.5 pixels`

### Attempt 2 — OverflowBox (❌ FAILED — infinite size crash)

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

**Error:** `RenderConstrainedOverflowBox object was given an infinite size during layout.` and `RRect argument contained a NaN value.`

**Why it failed:** `OverflowBox` inside a `Positioned` with `left: 0, right: 0` receives a constrained width, but the height becomes infinite because `Positioned` doesn't constrain the height. This causes the OverflowBox to receive infinite height constraints, crashing the layout.

### Attempt 3 — UnconstrainedBox (❌ FAILED — 31px overflow on both sides)

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

**Error:** `Right overflowed by 31 pixels` AND `Left overflowed by 31 pixels`

**Why it failed:** `UnconstrainedBox` allows its child to size itself freely, but the widget itself still **reports overflow** when its child is larger than the constraints it receives from its parent. `clipBehavior: Clip.none` only prevents visual clipping, it does NOT suppress overflow error reporting.

### Final Solution (✅ WORKS)

Remove `left` and `right` entirely from `Positioned`. Let the Stack's alignment handle centering:

```dart
// ✅ SOLUTION THAT WORKS
Stack(
  clipBehavior: Clip.none,                  // Allow visual overflow
  alignment: Alignment.bottomCenter,        // Auto-center horizontally
  children: [
    // ... bar widget ...
    if (isActive && activeSpendAmount > 0)
      Positioned(
        bottom: barHeight + 8,
        // NO left/right — this is the key fix
        child: _ChartTooltip(
          label: CurrencyFormatter.formatRupiah(activeSpendAmount),
        ),
      ),
  ],
)
```

### Why It Works

| Aspect | Behavior |
|---|---|
| **No `left`/`right`** | `Positioned` doesn't force horizontal constraints → child sizes itself intrinsically (based on content) |
| **Stack `alignment: bottomCenter`** | Unconstrained `Positioned` children are automatically positioned at horizontal center |
| **`clipBehavior: Clip.none`** | Tooltip renders visually beyond Stack bounds without any overflow error |
| **No wrapper needed** | Eliminates `OverflowBox`, `UnconstrainedBox`, or `Center` complications |

### Files Changed

- [`analytics_screen.dart`](file:///d:/Coding/Recify/lib/presentation/screens/analytics_screen.dart) — Bar chart section in `_AnalyticsScreenState.build()`, around line 244-252

---

## Quick Reference Checklist

When encountering rendering bugs on Android devices:

- [ ] **Red/solid color band on blur?** → Add `ColoredBox` base layer before `BackdropFilter`
- [ ] **Negative margin crash?** → Replace with `Transform.translate(offset: Offset(dx, dy))`
- [ ] **Overflow on tooltip/label?** → Remove `left`/`right` from `Positioned`, rely on Stack alignment
- [ ] **Test on Mali GPU device** → Infinix, some Samsung, Mediatek devices
- [ ] **Test edge cases** → Tap the first and last bar in the chart to verify no overflow on edges

---

## Summary of All Fixes

| Bug | Error Message | Fix |
|---|---|---|
| Red band GPU artifact | _(visual only, no console error)_ | `ColoredBox` + `RepaintBoundary` outside `ClipRRect` |
| Negative margin crash | `margin.isNonNegative is not true` | `Transform.translate(offset: Offset(0, -1))` |
| Tooltip overflow | `overflowed by N pixels` | Remove `left`/`right` from `Positioned` |
