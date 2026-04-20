@echo off
REM KwartX Demo Data Setup Script for Windows
REM This script helps set up demo data for testing

setlocal enabledelayedexpansion

echo.
echo ===============================================================
echo    KwartX Demo Data Generator
echo ===============================================================
echo.

REM Get Firebase Project ID
if "%1%"=="" (
    echo WARNING: No project ID provided
    echo Usage: setup-demo-data.bat ^<firebase-project-id^>
    echo.
    echo Example: setup-demo-data.bat kwartx-demo
    echo.
    set /p PROJECT_ID="Enter your Firebase Project ID: "
    if "!PROJECT_ID!"=="" (
        echo ERROR: Project ID is required
        exit /b 1
    )
) else (
    set PROJECT_ID=%1%
)

echo Project ID: %PROJECT_ID%
echo.

REM Check if service account file exists
set SERVICE_ACCOUNT_PATH=.\config\firebase-adminsdk.json

if not exist "%SERVICE_ACCOUNT_PATH%" (
    echo WARNING: Service account file not found!
    echo.
    echo Please download it from Firebase Console:
    echo.
    echo  1. Open https://console.firebase.google.com
    echo  2. Select your project
    echo  3. Go to Settings (gear icon) ^> Service Accounts
    echo  4. Click 'Generate New Private Key'
    echo  5. Save as: %SERVICE_ACCOUNT_PATH%
    echo.
    pause
    
    if not exist "%SERVICE_ACCOUNT_PATH%" (
        echo ERROR: Service account file still not found at %SERVICE_ACCOUNT_PATH%
        exit /b 1
    )
)

echo. Service account found
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed
    echo Please install Node.js from https://nodejs.org/
    exit /b 1
)

echo. Node.js is installed
echo.

REM Install dependencies
echo Installing dependencies...
cd scripts
if not exist "node_modules" (
    call npm install --silent
) else (
    echo. Dependencies already installed
)
cd ..

echo.
echo Running demo data generator...
echo.

REM Run the demo data generator
set GOOGLE_APPLICATION_CREDENTIALS=%SERVICE_ACCOUNT_PATH%
call node scripts/generate-demo-data.js %PROJECT_ID%

if errorlevel 1 (
    echo.
    echo ERROR: Error generating demo data
    exit /b 1
) else (
    echo.
    echo ===============================================================
    echo OK: Demo data generated successfully!
    echo ===============================================================
    echo.
    
    echo Next Steps:
    echo.
    echo  1. Create Firebase Auth users (optional):
    echo     - Go to Firebase Console ^> Authentication
    echo     - Create user: john@example.com (pass: Demo@1234)
    echo     - Create user: sarah@example.com (pass: Demo@1234)
    echo     - Create user: mike@example.com (pass: Demo@1234)
    echo.
    
    echo  2. Update Flutter app config:
    echo     - Download google-services.json from Firebase Console
    echo     - Place in android/app/
    echo     - Update ios/Runner/GoogleService-Info.plist
    echo.
    
    echo  3. Run the Flutter app:
    echo     flutter run
    echo.
    
    echo  4. Sign in with demo account (e.g., john@example.com)
    echo.
    pause
)
