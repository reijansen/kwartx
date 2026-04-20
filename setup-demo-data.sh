#!/bin/bash

# KwartX Demo Data Setup Script
# This script helps set up demo data for testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   KwartX Demo Data Generator${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Get Firebase Project ID
if [ -z "$1" ]; then
    echo -e "${YELLOW}⚠️  No project ID provided${NC}"
    echo -e "Usage: ./setup-demo-data.sh <firebase-project-id>"
    echo -e "\nExample: ./setup-demo-data.sh kwartx-demo\n"
    
    read -p "Enter your Firebase Project ID: " PROJECT_ID
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}❌ Project ID is required${NC}"
        exit 1
    fi
else
    PROJECT_ID=$1
fi

echo -e "${BLUE}Project ID: ${GREEN}$PROJECT_ID${NC}\n"

# Check if service account file exists
SERVICE_ACCOUNT_PATH="./config/firebase-adminsdk.json"

if [ ! -f "$SERVICE_ACCOUNT_PATH" ]; then
    echo -e "${YELLOW}⚠️  Service account file not found!${NC}"
    echo -e "Please download it from Firebase Console:\n"
    echo -e "  1. Open ${BLUE}https://console.firebase.google.com${NC}"
    echo -e "  2. Select your project"
    echo -e "  3. Go to ⚙️ Settings → Service Accounts"
    echo -e "  4. Click 'Generate New Private Key'"
    echo -e "  5. Save as: ${GREEN}config/firebase-adminsdk.json${NC}\n"
    
    read -p "Press Enter after you've saved the service account key..."
    
    if [ ! -f "$SERVICE_ACCOUNT_PATH" ]; then
        echo -e "${RED}❌ Service account file still not found at $SERVICE_ACCOUNT_PATH${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Service account found${NC}\n"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo -e "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✓ Node.js is installed${NC}\n"

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
cd scripts
if [ ! -d "node_modules" ]; then
    npm install --silent
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi
cd ..

echo -e "\n${BLUE}🚀 Generating demo data...${NC}\n"

# Run the demo data generator
GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_PATH" node scripts/generate-demo-data.js "$PROJECT_ID"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Demo data generated successfully!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${BLUE}📊 Next Steps:${NC}\n"
    echo -e "  1. Create Firebase Auth users (optional):"
    echo -e "     • Go to Firebase Console → Authentication"
    echo -e "     • Create user: john@example.com (pass: Demo@1234)"
    echo -e "     • Create user: sarah@example.com (pass: Demo@1234)"
    echo -e "     • Create user: mike@example.com (pass: Demo@1234)\n"
    
    echo -e "  2. Update Flutter app config:"
    echo -e "     • Download google-services.json from Firebase Console"
    echo -e "     • Place in android/app/"
    echo -e "     • Update ios/Runner/GoogleService-Info.plist\n"
    
    echo -e "  3. Run the Flutter app:"
    echo -e "     ${BLUE}flutter run${NC}\n"
    
    echo -e "  4. Sign in with demo account (e.g., john@example.com)\n"
else
    echo -e "\n${RED}❌ Error generating demo data${NC}"
    exit 1
fi
