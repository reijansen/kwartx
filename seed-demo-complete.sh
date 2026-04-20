#!/bin/bash

# Complete Demo Seeder for KwartX (Mac/Linux)
# Creates both Firebase Auth users AND Firestore data

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   KwartX Complete Demo Seeder${NC}"
echo -e "${BLUE}   (Auth Users + Firestore Data)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

if [ -z "$1" ]; then
    echo -e "${YELLOW}⚠️  No project ID provided${NC}"
    read -p "Enter your Firebase Project ID: " PROJECT_ID
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}❌ Project ID is required${NC}"
        exit 1
    fi
else
    PROJECT_ID=$1
fi

echo -e "${BLUE}Project ID: ${GREEN}$PROJECT_ID${NC}\n"

SERVICE_ACCOUNT_PATH="./config/firebase-adminsdk.json"

if [ ! -f "$SERVICE_ACCOUNT_PATH" ]; then
    echo -e "${RED}❌ Service account file not found!${NC}"
    echo -e "Please:\n"
    echo -e "  1. Go to ${BLUE}https://console.firebase.google.com${NC}"
    echo -e "  2. Select your project"
    echo -e "  3. Go to ⚙️ Settings → Service Accounts"
    echo -e "  4. Click 'Generate New Private Key'"
    echo -e "  5. Save as: ${GREEN}config/firebase-adminsdk.json${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ Service account found${NC}\n"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo -e "Please install from https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✓ Node.js is installed${NC}\n"

echo -e "${BLUE}📦 Installing dependencies...${NC}"
cd scripts
if [ ! -d "node_modules" ]; then
    npm install --silent
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi
cd ..

echo -e "\n${BLUE}🚀 Running complete demo seeder...${NC}"
echo -e "${BLUE}This will create auth users AND Firestore data\n${NC}"

GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_PATH" node scripts/seed-demo-complete.js "$PROJECT_ID"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Demo seeding complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${BLUE}📱 Next Steps:${NC}\n"
    echo -e "  1. Run the Flutter app:"
    echo -e "     ${BLUE}flutter run${NC}\n"
    
    echo -e "  2. Sign in with demo credentials:"
    echo -e "     Email: john@example.com"
    echo -e "     Password: Demo@1234\n"
    
    echo -e "  3. Explore all features:"
    echo -e "     - Dashboard with balances"
    echo -e "     - Expenses (5 samples created)"
    echo -e "     - Roommate settlements"
    echo -e "     - Invites management"
    echo -e "     - Room details with members\n"
    
    echo -e "  4. Test multi-user:"
    echo -e "     - Sign out"
    echo -e "     - Sign in as sarah@example.com (Demo@1234)"
    echo -e "     - See different perspective\n"
else
    echo -e "\n${RED}❌ Error seeding demo data${NC}"
    exit 1
fi
