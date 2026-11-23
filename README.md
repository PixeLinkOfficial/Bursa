# Prpaha – TV rates board (Android)

An Arabic, full-screen exchange-rate board for an Android TV:

- **USD → IQD** (per 100 $), large, at the top
- **EUR → IQD** (per 100 €) and **EUR → USD** (per 100 €, shown in $) underneath
- Buy (شراء) and sell (بيع) prices for each pair, with flags, a live clock and date, and the time of the last update
- A three-line menu button at the top right opens a side panel with **حساب المسؤول** (admin account)
- Login: `admin` / `123`. You can change these at the top of `lib/admin.dart`.
- Rates are saved on the TV itself. They survive restarts and power cuts, and no internet is needed.

## Get the APK without installing anything (GitHub builds it)

1. Create a free account at <https://github.com>, then click **+ → New repository**.
   Name it `perbeha-tv`, choose **Private**, and click **Create repository**.
2. On the new repository page, click **uploading an existing file**. Open this folder in
   Explorer, select **everything inside it** (`.github`, `android_overrides`, `assets`, `lib`,
   `pubspec.yaml`, and so on), and drag it into the browser. Then click **Commit changes**.
   - Check that a `.github` folder now appears in the file list. If it doesn't, click
     **Add file → Create new file**, type `.github/workflows/build-apk.yml` as the name,
     paste in the contents of that file from this folder, and commit.
3. Open the **Actions** tab. A **Build APK** run starts by itself and takes about 5–10 minutes.
   If nothing is running, click **Build APK → Run workflow**.
4. When it shows a green tick, open the run. Under **Artifacts**, download
   **perbeha-tv-apk**, then unzip it to get `app-release.apk`.

Every time you upload changed files, GitHub builds a new APK automatically.

## Install on the TV

1. Copy `app-release.apk` to a USB stick and plug it into the TV.
   You can also use a "Send files to TV" app.
2. On the TV, open a file manager (for example *File Commander* or *X-plore* from the Play Store)
   and open the APK. Allow **Install unknown apps** when the TV asks.
3. The app appears on the TV home screen as **Prpaha**.

## Using it with the TV remote

- Press any arrow or the **OK** button. The menu button (☰, top right) lights up in gold.
  Press **OK** to open the side panel. The remote's **Menu** key also opens it directly.
- Choose **حساب المسؤول**, then enter `admin` and `123`.
- Type the buy and sell prices for each pair and press **حفظ الأسعار**. The board updates right away.
  Leave a box empty to show "—".
- The gold highlight disappears by itself after 15 seconds without remote presses.

## Building on a PC with Flutter instead

With Flutter and Android Studio installed, run this from this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_local.ps1
```

## What's where

| Path | What it is |
|---|---|
| `lib/board.dart` | The TV screen: layout, clock, rate cards, side menu |
| `lib/admin.dart` | Login dialog and the rates editor |
| `lib/rates.dart` | Currency pairs and saving/loading rates |
| `lib/flags.dart` | US, EU and Iraq flags, drawn in code |
| `lib/format.dart` | Number formatting and Arabic dates |
| `lib/theme.dart` | Colours and fonts |
| `assets/images/emblem.png` | Gold logo emblem, cut out of `imgs/black.jpeg` |
| `android_overrides/` | TV launcher banner, app icon, dark splash screen, keep-screen-on and storage code |
| `.github/workflows/build-apk.yml` | The cloud build |
