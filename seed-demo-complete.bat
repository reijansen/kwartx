@echo off
REM Complete Demo Seeder for KwartX
REM Creates both Firebase Auth users AND Firestore data
REM Perfect for professor demo!

setlocal enabledelayedexpansion

echo.
echo ===============================================================
echo    KwartX Complete Demo Seeder
echo    (Auth Users + Firestore Data)
echo ===============================================================
echo.

if "%1%"=="" (
    echo WARNING: No project ID provided
    echo Usage: seed-demo-complete.bat ^<firebase-project-id^>
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
    echo ERROR: Service account file not found at %SERVICE_ACCOUNT_PATH%
    echo.
    echo Please:
    echo  1. Go to Firebase Console ^(https://console.firebase.google.com^)
    echo  2. Select your project
    echo  3. Go to Settings ^(gear icon^) ^> Service Accounts
    echo  4. Click 'Generate New Private Key'
    echo  5. Save as: %SERVICE_ACCOUNT_PATH%
    echo.
    exit /b 1
)

echo. Service account found
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed
    echo Please install from https://nodejs.org/
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
echo Running complete demo seeder...
echo This will create auth users AND Firestore data
echo.

REM Run the seeder
set GOOGLE_APPLICATION_CREDENTIALS=%SERVICE_ACCOUNT_PATH%
call node scripts/seed-demo-complete.js %PROJECT_ID%

if errorlevel 1 (
    echo.
    echo ERROR: Error seeding demo data
    exit /b 1
) else (
    echo.
    echo ===============================================================
    echo OK: Demo seeding complete!
    echo ===============================================================
    echo.
    
    echo Next Steps:
    echo.
    echo  1. Run the Flutter app:
    echo     flutter run
    echo.
    
    echo  2. Sign in with demo credentials:
    echo     Email: john@example.com
    echo     Password: Demo@1234
    echo.
    
    echo  3. Explore all features:
    echo     - Dashboard with balances
    echo     - Expenses (5 samples created)
    echo     - Roommate settlements
    echo     - Invites management
    echo     - Room details with members
    echo.
    
    echo  4. Test multi-user:
    echo     - Sign out
    echo     - Sign in as sarah@example.com (Demo@1234)
    echo     - See different perspective
    echo.
    
    pause
)
