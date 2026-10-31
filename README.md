# Recify — Smart Offline-First Expense Tracker & Receipt OCR

<p align="center">
  A private, offline-first personal finance app for Android with 100% on-device receipt OCR (Google ML Kit). No cloud, no online account — your data never leaves the phone.
</p>

---

## Features

- **On-device receipt OCR (offline AI)** — scan store receipts (Indomaret, Alfamart, restaurants, etc.) and extract totals and line items instantly on the device via Google ML Kit. Optional Gemini parsing enriches extracted items (requires internet + API key, see Prerequisites).
- **Local multi-user auth** — sign up and sign in entirely offline. Passwords are stored as salted hashes, and all data (wallets, categories, transactions, budgets) is isolated per account.
- **Multi-currency with live rates** — record transactions in 15 currencies (IDR, USD, EUR, JPY, SGD, and more) with country flags. Rates come from [open.er-api.com](https://open.er-api.com), cached daily (shown even while offline); balances always consolidate into IDR.
- **Multi-wallet** — manage cash, bank accounts, and e-wallets with a combined balance in the hero card and a quick account switcher.
- **Monthly budgets per category** — set a spending cap per category each month and track progress and headroom with a progress bar.
- **Local transaction notifications** — an Android notification fires as soon as an expense or income is saved; tapping it opens the transaction detail (full deep-link routing, works after a cold start too).
- **JSON backup & restore** — export an entire account to `Recify_Backup_*.json` in the Downloads folder and restore it anytime from within the app.
- **Statistics & analytics** — per-category spending charts, periodic cash flow, trends, and category insights computed per period.
- **Global search** — find transactions across all wallets and categories from a single screen.
- **Smart manual entry**:
  - Automatic thousands separators (`.`) while typing amounts.
  - Flexible, interactive horizontal category carousel.
  - Color coding by type (red for expenses, green for income).
- **Bilingual UI (English / Indonesian)** — every screen and notification supports both languages; user-recorded transaction data is never translated.
- **System / light / dark themes** — the dark *Obsidian Flux* palette is the core identity; the light palette is hand-tuned rather than a mechanical inversion.
- **CSV & Excel (.xlsx) export** — pick the format from a dialog and save transaction recaps to the Downloads folder.
- **Zero-cloud privacy** — every transaction, category, wallet, budget, receipt photo, and the Gemini API key live only in a local SQLite database on your device.

---

## Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart ^3.10)
- **State management**: [Provider](https://pub.dev/packages/provider)
- **Local database**: [sqflite](https://pub.dev/packages/sqflite)
- **Local auth**: salted password hashing + SQLite user repository (no backend)
- **On-device OCR**: [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- **AI receipt parsing**: [google_generative_ai](https://pub.dev/packages/google_generative_ai) (Gemini)
- **Live exchange rates**: [open.er-api.com](https://open.er-api.com) via [http](https://pub.dev/packages/http), cached daily in [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Local notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Local export**: [csv](https://pub.dev/packages/csv) and [excel](https://pub.dev/packages/excel)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Typography**: [Google Fonts (Plus Jakarta Sans)](https://pub.dev/packages/google_fonts)
- **Image handling**: [image](https://pub.dev/packages/image), [image_picker](https://pub.dev/packages/image_picker)

---

## Getting Started

### Prerequisites
- Flutter SDK (v3.38.1 or newer — required by `flutter_local_notifications` 22.x)
- Android SDK and JDK 17
- A physical Android device or emulator (**minSdk 24 / Android 7.0+**)
- *(Optional)* a Gemini API key from [aistudio.google.com](https://aistudio.google.com/app/apikey), entered in-app: Settings → Gemini API Keys

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MochamadAbdulRouf/Recify.git
   cd Recify
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app on a device:**
   ```bash
   flutter run
   ```

4. **Create the first local account (sign up):**
   Fill in name, email, and password — no connection is needed anywhere. Your credentials are shown for 5 seconds to confirm, then you are in.

5. **Build a release APK:**
   ```bash
   flutter build apk --release
   ```
   The output lands in `build/app/outputs/flutter-apk/app-release.apk` (the `dist/` folder is used as a local release-artifact staging area and is git-ignored).

### Running tests

```bash
flutter test
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/        # The 15 supported currencies (currencies.dart)
│   ├── i18n/             # AppStrings (bilingual English/Indonesian)
│   ├── services/         # ExchangeRateService (live rates + caching), ProfileService
│   ├── theme/            # Obsidian Flux: AppColors (light/dark), AppMotion, AppTheme, AppTypography
│   └── utils/            # CurrencyFormatter, PeriodAggregator, TrendCalculator, TransactionFilter, PasswordHasher, etc.
├── data/
│   ├── local/            # SQLite DatabaseHelper (budgets table & period indexes) + SeedData
│   ├── models/           # Transaction (+ items), Category, Wallet, Budget, User, ParsedReceipt
│   └── repositories/     # FinanceRepository, AuthRepository (salted hash), ReceiptArchiveManager
├── domain/
│   ├── backup/           # BackupManager (JSON export -> Downloads, restore)
│   ├── export/           # ReportExporter (CSV & Excel generator)
│   ├── notifications/    # NotificationBuilder
│   └── ocr/              # MLKitReceiptScanner, IndonesianReceiptParser, GeminiReceiptParser, ReceiptValidator
├── presentation/
│   ├── components/       # FloatingIslandNavBar (responsive), ObsidianHeroCard, QuickActionGrid, BudgetProgressBar, StickyFrostedAppBar, etc.
│   ├── providers/        # Finance, Scanner, Auth, Theme, Locale, ExchangeRate providers
│   ├── screens/          # AuthGate/Login/Signup/Credentials, Dashboard, ManualTransaction, QuickVerification, History/Transaction detail, GlobalSearch, Analytics, NotificationCenter, Settings
│   ├── services/         # TransactionNotificationService & NotificationRouter
│   └── widgets/          # CurrencyPickerField, WalletPickerField
└── main.dart             # Flutter application entrypoint
```

---

## Releases

Prebuilt binaries are available on the [Releases](https://github.com/MochamadAbdulRouf/Recify/releases) page: a universal Android APK covering arm64-v8a and armeabi-v7a for Android 7.0+.

---

## License
Copyright © 2026 **Recify**. Licensed under the [MIT License](LICENSE).
