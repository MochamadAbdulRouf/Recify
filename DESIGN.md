---
name: Obsidian Flux
colors:
  surface: '#121318'
  surface-dim: '#121318'
  surface-bright: '#38393f'
  surface-container-lowest: '#0d0e13'
  surface-container-low: '#1a1b21'
  surface-container: '#1e1f25'
  surface-container-high: '#292a2f'
  surface-container-highest: '#34343a'
  on-surface: '#e3e1e9'
  on-surface-variant: '#c3c5d8'
  inverse-surface: '#e3e1e9'
  inverse-on-surface: '#2f3036'
  outline: '#8d90a1'
  outline-variant: '#434655'
  surface-tint: '#b5c4ff'
  primary: '#b5c4ff'
  on-primary: '#00297a'
  primary-container: '#2f6bff'
  on-primary-container: '#000318'
  inverse-primary: '#0051e0'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffb2b7'
  on-tertiary: '#67001b'
  tertiary-container: '#df2f51'
  on-tertiary-container: '#ffffff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b5c4ff'
  on-primary-fixed: '#00174d'
  on-primary-fixed-variant: '#003cac'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdadb'
  tertiary-fixed-dim: '#ffb2b7'
  on-tertiary-fixed: '#40000d'
  on-tertiary-fixed-variant: '#92002a'
  background: '#121318'
  on-background: '#e3e1e9'
  surface-variant: '#34343a'
  bg-canvas: '#090A0F'
  bg-surface: '#12141D'
  bg-surface-elevated: '#1B1E2B'
  text-primary: '#FFFFFF'
  text-secondary: '#8E95A5'
  border-subtle: rgba(255, 255, 255, 0.08)
  mesh-indigo: '#4F46E5'
  mesh-cyan: '#06B6D4'
  mesh-violet: '#8B5CF6'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-reg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-bold:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 40px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered for a premium, high-tech financial experience. It targets a sophisticated audience that values precision, speed, and status. The aesthetic is a fusion of **Minimalism** and **Glassmorphism**, leveraging a deep OLED-black foundation to allow vibrant functional accents and atmospheric mesh gradients to pop. 

The emotional goal is "effortless control." By utilizing translucent layers and fluid micro-interactions, the UI feels lightweight and responsive, transforming the often-chore-like task of receipt scanning and expense tracking into a tactile, engaging ritual. High-contrast elements ensure accessibility while maintaining a "dark mode first" luxury feel.

## Colors

The palette is anchored by `bg-canvas`, an OLED-optimized deep navy-black. Functional colors are highly saturated to ensure they pierce through the dark background:
- **Primary (Electric Blue):** Used for critical actions, active states, and navigation highlights.
- **Positive/Negative:** Strictly reserved for financial trends and status indicators.
- **Surface Tiers:** `bg-surface` serves as the primary card container, while `bg-surface-elevated` provides depth for interactive elements like inputs or hover states.
- **Mesh Gradients:** A signature blend of indigo, cyan, and violet is applied to high-level hero elements (like virtual cards) to provide a sense of luxury and depth.

## Typography

This design system uses **Plus Jakarta Sans** exclusively. Its geometric clarity and modern proportions make it ideal for both large financial figures and dense transaction metadata. 

- **Tabular Figures:** Always use the font's tabular lining feature for transaction amounts to ensure vertical alignment in lists and charts.
- **Scale:** `display-lg` is reserved for total balances. `label-md` is used for category tags and timestamps.
- **Contrast:** Utilize `text-primary` for critical data and `text-secondary` for supporting metadata to create a clear information hierarchy.

## Layout & Spacing

The layout follows a **fluid grid** model with a focus on "safe area" padding for mobile devices. 
- **The Floating Island:** Navigation is contained within a blurred, floating container at the bottom of the screen, detached from the edges.
- **Vertical Rhythm:** A 4px baseline grid governs all spacing. Transaction rows use 16px internal padding. 
- **Grouping:** Use `stack-lg` (24px) to separate major sections (e.g., Hero Card vs. Recent Activity) and `stack-sm` (8px) for internal element grouping (e.g., Icon and Label).

## Elevation & Depth

Depth is conveyed through **Glassmorphism** and **Tonal Layers** rather than heavy shadows.
- **Glassmorphism:** Navigation bars and top-level modals use a `Backdrop Blur` (20px-30px) with a semi-transparent `border-subtle` stroke.
- **Stacking:** `bg-canvas` (base) -> `bg-surface` (cards) -> `bg-surface-elevated` (active items).
- **Strokes:** Use 1px internal strokes (`border-subtle`) instead of drop shadows to define boundaries. This keeps the UI looking sharp and clinical.
- **Glow:** The primary action button (Scan) features a subtle outer glow using the Primary color at 20% opacity to denote its importance.

## Shapes

The shape language is consistently **Rounded**, providing a friendly counter-balance to the stark dark color palette.
- **Standard Cards:** 1rem (16px) corner radius.
- **Action Buttons:** 1rem (16px) or fully pill-shaped for smaller chips.
- **Input Fields:** 0.75rem (12px) for a modern, approachable feel.
- **Scan FAB:** Circular to distinguish it as the primary app trigger.

## Components

### Buttons
- **Primary:** Solid `accent-primary` with white text. 
- **Secondary:** `bg-surface-elevated` with a 1px `border-subtle`.
- **Ghost:** No background, `text-secondary` for inactive or "View All" triggers.

### Cards
All cards use `bg-surface` with a 1px `border-subtle`. The "Main Wallet" card is the only element allowed to use the **Mesh Gradient** background to signify its status as the primary data source.

### Input Fields
Inputs use `bg-surface-elevated`. The active state is indicated by an `accent-primary` 1px border. Use tabular figures for the amount entry field.

### Chips & Status
- **Transaction Tags:** Pill-shaped with `bg-surface-elevated`. 
- **Trend Indicators:** Small chips with 10% opacity of the status color (green/red) and 100% opacity text for the labels.

### Lists
Transaction items should have a minimum height of 72px. Icons are housed in a 40px rounded-lg container with 8% white opacity to provide a "glass" icon-backplate effect.

### Floating Navigation
A centered, blurred "Island" containing 4 icons and a prominent circular "Scan" button. The Scan button is elevated and uses the mesh gradient or solid Primary color.