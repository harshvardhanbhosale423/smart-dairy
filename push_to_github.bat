@echo off
title Smart Dairy - Push to GitHub
echo =======================================================
echo          Smart Dairy - GitHub Push Helper
echo =======================================================
echo.
echo Target Repository:
echo https://github.com/harshvardhanbhosale423/smart-dairy.git
echo.
echo -------------------------------------------------------
echo NOTE: Make sure you clicked "Create repository" once at:
echo https://github.com/new?name=smart-dairy
echo -------------------------------------------------------
echo.

set DEFAULT_URL=https://github.com/harshvardhanbhosale423/smart-dairy.git
set /p REPO_URL="Press ENTER to push to %DEFAULT_URL% (or paste new URL): "

if "%REPO_URL%"=="" set REPO_URL=%DEFAULT_URL%

echo.
echo [1/3] Setting remote repository...
git remote remove origin 2>nul
git remote add origin %REPO_URL%

echo [2/3] Preparing branch 'main'...
git branch -M main

echo [3/3] Uploading all project files to GitHub...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =======================================================
    echo [SUCCESS] All files uploaded to GitHub successfully!
    echo =======================================================
    echo.
    echo DIRECT APK DOWNLOAD LINK:
    echo Open: https://github.com/harshvardhanbhosale423/smart-dairy/actions
    echo.
    echo Click "Build Release APK" -^> Download "SmartDairy-Release-APK"
    echo.
) else (
    echo.
    echo [NOTE] If you saw "repository not found", please open:
    echo https://github.com/new?name=smart-dairy
    echo and click the green "Create repository" button first!
)

pause
