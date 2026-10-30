@echo off
title Smart Dairy - Build APK
echo =======================================================
echo          Smart Dairy - Android APK Builder
echo =======================================================
echo.

where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter SDK is not detected in your PATH.
    echo.
    echo To build the APK on your machine:
    echo 1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
    echo 2. Extract to C:\src\flutter and add C:\src\flutter\bin to your System PATH.
    echo 3. Re-run this script.
    echo.
    echo OR use GitHub Actions (Free, No Setup Required):
    echo Push this project to GitHub and download the APK from the Actions tab!
    echo.
    pause
    exit /b 1
)

echo [1/3] Fetching Flutter dependencies...
call flutter pub get

echo.
echo [2/3] Running tests to verify financial calculations...
call flutter test

echo.
echo [3/3] Compiling Release APK...
call flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =======================================================
    echo [SUCCESS] APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-release.apk
    echo =======================================================
    echo.
    echo Opening output folder...
    explorer.exe "build\app\outputs\flutter-apk"
) else (
    echo.
    echo [ERROR] Build failed. Please check the logs above.
)

pause
