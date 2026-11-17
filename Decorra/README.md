# Decorra (Flutter)

Flutter version of the Decorra Android app for a décor and events business.
It has two sides in one app: **clients** browse the portfolio and request quotes,
and **decorators** (the business) manage themes, items, quotes, payments, events
and team. It reuses the existing Firebase project, so existing accounts keep working.

## What the app does

### Client side
| Area | What it does |
|---|---|
| Sign in / register, password reset | Role is checked on sign in, so clients and decorators land on the right home screen |
| Home, Quotes, Chats, Profile | Bottom navigation shell |
| **Portfolio** | Themes grid, search, theme detail, rentable items, inspiration |
| **Customize a theme + request a quote** | Pick items and quantities, event details, guests, venue, catering |
| **Drafts** | Unsent quote requests are saved and can be finished later |
| **My Quotes** | Live status tracker: requested, being prepared, ready, approved, deposit paid, in progress, complete |
| **Approve or decline** | The client accepts or declines a quote that has been sent |
| **Download approved quotation (new)** | Once a quote is approved, the client can download it as a PDF |
| Deposit and payments | Bank details appear after approval; recorded payments and outstanding balance are shown |
| Chat and notifications | Chat with the decorator, notifications screen |

### Decorator (admin) side
| Area | What it does |
|---|---|
| Dashboard and activity | Overview of quotes, events and recent activity |
| Themes and items | Add, edit and delete themes and rentable items, with photos |
| Quotes | Review requests, build the quote, fees, discount, VAT, send to the client |
| Invoices and payments | Generate an invoice, record payments |
| Events and portfolio | Create, edit, publish or move events to drafts, delete |
| Clients, messages, notifications | Client list and chat |
| Freelancers and team | Assign freelancers to quotes, extra-freelancer rule for large guest counts |
| Business profile and bank details | Shown on invoices and quotations |
| Stock check | Items are reserved from approved quotes on the same event date |

### Both sides
- Light, dark or system theme, saved on the phone
- Languages: English, Afrikaans, isiZulu
- Notification settings and privacy policy
- Push notifications through a small free worker (see `decorra-push/`)

## What is new in this update

- **Approved quotation download.** On a client's quote screen, a
  **Download approved quotation** button appears once the quote is approved (and stays
  for deposit paid, in progress and complete). It creates a PDF with the business
  details, client and event details, itemised prices, transport, labour, discount,
  VAT, total, deposit, balance, and the deposit bank details. Freelancer costs are
  internal and are never included. The phone's share / save sheet opens so the client
  can save it to Files or Drive, or send it by WhatsApp or email.
  Code: `lib/services/quote_pdf.dart`.
- **Automated tests** for pricing, quotes, the PDF and the shared widgets (`test/`).
- **Continuous integration.** GitHub Actions runs analyze and the tests on every push
  and pull request (`.github/workflows/flutter-ci.yml`).
- Cleaned-up analyzer warnings (`BuildContext` use after `await`, unused names).

## Setup

### 1. Tools
Install the Flutter SDK, then in VS Code install the **Flutter** and **Dart**
extensions. Run `flutter doctor` and fix anything it flags for Android.

### 2. Packages
From the `decorra` folder:
```
flutter pub get
```
The app uses: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`,
`cached_network_image`, `image_picker`, `http`, `provider`, `shared_preferences`,
`flutter_localizations`, and (new) `pdf` and `printing` for the quotation download.

If you are adding the two new ones to an existing checkout:
```
flutter pub add pdf printing
```

### 3. Connect Firebase
```
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=decorra-ee952
```
This creates `lib/firebase_options.dart`.

### 4. Photo uploads (Cloudinary, free)
1. Create a free account at cloudinary.com and copy your **Cloud name**.
2. Settings, Upload, **Upload presets**, add a preset with **Signing mode: Unsigned**.
3. Put both values in `lib/config.dart`.

### 5. Firestore rules
The app reads and writes these collections: `users`, `threads`, `themes`, `items`,
`events`, `quotes`, `payments`, `teamMessages`, `business`, `userSettings`.
`firestore.rules.snippet` shows the `themes` and `items` rules. Make sure your rules also let:
- a client read **their own** quotes, and change a quote only from `sent` to `approved` or `declined`
- any signed-in user read `business/profile` and `business/payment` (used on the quotation PDF)
- only decorators write themes, items, payments and business details
- nobody edit their own `role`

### 6. Push notifications
Push is optional. The worker in `decorra-push/` checks Firestore once a minute and sends
through FCM. It runs on the free Cloudflare plan and needs one secret,
`FIREBASE_SERVICE_ACCOUNT` (the service account key JSON). The app saves each phone's
token on `users/{uid}.fcmTokens`.

### 7. Android release permission
Release builds need the internet permission in
`android/app/src/main/AndroidManifest.xml`, above `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 8. Run
Start an emulator or plug in a phone with USB debugging on, then press **F5** in VS Code
or run `flutter run`. `flutter devices` lists what Flutter can see.

## Testing

```
flutter test                 # run every test
flutter test --coverage      # also writes coverage/lcov.info
flutter analyze              # static checks
```

| File | What it covers |
|---|---|
| `test/pricing_test.dart` | VAT, fees, discount (including out-of-range), rand and cents parsing, money and date text, guest limits, item lines |
| `test/quote_test.dart` | Quote totals, defaults, `copyWith`, status labels, who may download, reference and file name |
| `test/quote_pdf_test.dart` | The PDF builds (with and without business and bank details, no items, many items across pages) |
| `test/widget_test.dart` | `EmptyState` and `StatusBadge` widgets |

These tests need no Firebase, internet or phone, so they also run on the CI server.

## Continuous integration

`.github/workflows/flutter-ci.yml` runs on every push and pull request that touches
`decorra/`:

1. `flutter pub get`
2. `dart format` check (informational only)
3. `flutter analyze` (only errors fail the build)
4. `flutter test --coverage`, then uploads the coverage report

The workflow assumes the Git repository root is the folder that contains `decorra/`.
If your repository root **is** the Flutter project, delete the `defaults:` block in the
workflow and change `decorra/coverage/lcov.info` to `coverage/lcov.info`.

## Project layout
```
decorra/                      Flutter app
  lib/
    main.dart                 start-up + chooses client or decorator home
    config.dart               Cloudinary settings
    theme.dart, theme_dark.dart
    localization/             English, Afrikaans, isiZulu
    models/                   Quote, DecorEvent, DecorItem, DecorTheme, Payment, ...
    services/                 repositories, session, push, images, stock, quote_pdf
    screens/auth, client, admin, shared
    widgets/                  DecorImage, EmptyState, StatusBadge, pickers, ...
  test/                       unit and widget tests
decorra-push/                 free push worker (Cloudflare)
revive-technologies/          the business website
.github/workflows/            CI
firestore.rules.snippet       example Firestore rules
```
