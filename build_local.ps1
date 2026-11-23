# Builds the APK on a PC that has Flutter + Android SDK installed.
# Run from this folder:  powershell -ExecutionPolicy Bypass -File .\build_local.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# 1. Arabic font (IBM Plex Sans Arabic, SIL Open Font License)
New-Item -ItemType Directory -Force 'assets\fonts' | Out-Null
foreach ($w in 'Regular', 'Medium', 'SemiBold', 'Bold') {
  $out = "assets\fonts\IBMPlexSansArabic-$w.ttf"
  if (-not (Test-Path $out)) {
    Invoke-WebRequest -UseBasicParsing -OutFile $out `
      -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexsansarabic/IBMPlexSansArabic-$w.ttf"
  }
}

# 2. Standard Android project files (only created if missing)
if (-not (Test-Path 'android')) {
  flutter create --platforms=android --org com.perbeha --project-name perbeha_rates .
  if (Test-Path 'test') { Remove-Item -Recurse -Force 'test' }
}

# 3. TV settings, icon, banner and splash
Copy-Item -Recurse -Force 'android_overrides\*' 'android\app\src\main\'

# 4. Build
flutter build apk --release
Write-Host ""
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
