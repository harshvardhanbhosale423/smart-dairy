@echo off
title Smart Dairy - Push to GitHub
echo =======================================================
echo          Smart Dairy - GitHub Push Helper
echo =======================================================
echo.
echo When uploading via web browser drag-and-drop, GitHub limits
echo you to 100 files at a time. This script bypasses that limit
echo and uploads all project files automatically in one go!
echo.
echo -------------------------------------------------------
echo 1. Go to your empty repository on github.com
echo 2. Copy the HTTPS link (e.g. https://github.com/YourName/smart-dairy.git)
echo -------------------------------------------------------
echo.

set /p REPO_URL="Paste your GitHub repository URL here: "

if "%REPO_URL%"=="" (
    echo [ERROR] No URL provided. Exiting.
    pause
    exit /b 1
)

echo.
echo [1/3] Setting remote repository...
git remote remove origin 2>nul
git remote add origin %REPO_URL%

echo [2/3] Preparing branch...
git branch -M main

echo [3/3] Uploading all project files to GitHub...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =======================================================
    echo [SUCCESS] All files uploaded to GitHub successfully!
    echo =======================================================
    echo.
    echo NOW GET YOUR APK:
    echo 1. Open your repository on github.com
    echo 2. Click the "Actions" tab at the top.
    echo 3. Click "Build Release APK" and wait ~2 minutes.
    echo 4. Click "SmartDairy-Release-APK" to download your APK!
    echo.
) else (
    echo.
    echo [ERROR] Push failed. If prompted for GitHub login in your browser,
    echo please approve it to complete the upload.
)

pause
