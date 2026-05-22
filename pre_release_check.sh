#!/usr/bin/env bash
#
# 🚀 Pre-Release / Pre-Merge Release Sanity check script
#

# Stop execution on any unhandled error inside bash utilities
set -e

# Color constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # Reset color

echo -e "${YELLOW}==================================================${NC}"
echo -e "${YELLOW}        🚀 RUNNING PRE-RELEASE SANITY CHECKS       ${NC}"
echo -e "${YELLOW}==================================================${NC}"

FAILED=0

# Ensure we are in the root directory of the project
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}Error: Run this script from the root directory containing pubspec.yaml${NC}"
  exit 1
fi

# 1. Formatting Check
echo -e "\n${YELLOW}[1/7] Checking Flutter code formatting...${NC}"
if ! dart format --set-exit-if-changed lib/ test/; then
  echo -e "${RED}❌ Format check failed! Run 'dart format lib/ test/' to format your code.${NC}"
  FAILED=1
else
  echo -e "${GREEN}✓ Code formatting is correct.${NC}"
fi

# 2. Static Analysis Check
echo -e "\n${YELLOW}[2/7] Running Flutter static analysis...${NC}"
if ! flutter analyze; then
  echo -e "${RED}❌ Static analysis failed! Please fix analyzer warnings/errors.${NC}"
  FAILED=1
else
  echo -e "${GREEN}✓ Flutter static analysis passed.${NC}"
fi

# 3. Unit/Widget Tests Check
echo -e "\n${YELLOW}[3/7] Running Flutter unit/widget tests...${NC}"
if ! flutter test; then
  echo -e "${RED}❌ Flutter tests failed!${NC}"
  FAILED=1
else
  echo -e "${GREEN}✓ All Flutter tests passed successfully.${NC}"
fi

# 4. Backend Package Audit
echo -e "\n${YELLOW}[4/7] Auditing backend dependencies...${NC}"
if [ -d "backend" ]; then
  cd backend
  # We audit for high severity vulnerabilities
  if ! npm audit --audit-level=high; then
    echo -e "${RED}❌ High/Critical vulnerabilities found in backend node packages! Run 'npm audit fix'.${NC}"
    FAILED=1
  else
    echo -e "${GREEN}✓ Backend dependency audit clean.${NC}"
  fi
  cd ..
else
  echo -e "${RED}❌ Backend directory not found!${NC}"
  FAILED=1
fi

# 5. Backend Smoke / Integration tests
echo -e "\n${YELLOW}[5/7] Running Backend Smoke & Integration Tests...${NC}"
if [ -d "backend" ]; then
  # Clean up any conflicting process running on port 3000
  if lsof -i :3000 -t >/dev/null; then
    echo -e "${YELLOW}Port 3000 is occupied. Terminating existing process...${NC}"
    CONFLICT_PID=$(lsof -i :3000 -t)
    kill -9 "$CONFLICT_PID" || true
    sleep 1
  fi

  # Start backend in background
  echo -e "${YELLOW}Starting backend server in background...${NC}"
  cd backend
  node server.js > server_smoke_test.log 2>&1 &
  SERVER_PID=$!
  cd ..

  # Wait for server to boot up
  sleep 3

  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo -e "${RED}❌ Backend server failed to start! Content of server_smoke_test.log:${NC}"
    cat backend/server_smoke_test.log || true
    FAILED=1
  else
    # Run integration checks (rate limiters, headers, signature generation)
    echo -e "${YELLOW}Running backend rate limiting & integration checks...${NC}"
    if ! NODE_PATH=backend/node_modules node "$HOME/.gemini/antigravity-ide/brain/6c3de98d-ccde-4593-8472-5cbf3e9918da/scratch/test_backend.js"; then
      echo -e "${RED}❌ Backend integration tests failed!${NC}"
      FAILED=1
    else
      echo -e "${GREEN}✓ Backend integration tests passed successfully.${NC}"
    fi

    # Kill background server cleanly
    echo -e "${YELLOW}Stopping backend server (PID: $SERVER_PID)...${NC}"
    kill -9 "$SERVER_PID" || true
    rm -f backend/server_smoke_test.log
  fi
else
  echo -e "${RED}❌ Backend directory not found! Skipping integration tests.${NC}"
  FAILED=1
fi

# 6. Hardcoded Secrets Check
echo -e "\n${YELLOW}[6/7] Scanning for hardcoded secrets...${NC}"
SECRET_FOUND=0

# Scan for suspected PEM private key block in client code
if grep -rn "BEGIN PRIVATE KEY" lib/ >/dev/null 2>&1; then
  echo -e "${RED}❌ Hardcoded Private Key PEM block detected in lib/ directory!${NC}"
  SECRET_FOUND=1
fi

# Scan for raw API Keys in code (ignoring .env and config scripts)
if grep -rnw --exclude-dir={.git,.dart_tool,build,node_modules} --exclude={.env,pre_release_check.sh,generate_keys.js,permissions_provider_test.dart} "SHARED_SIGNING_SECRET" . >/dev/null 2>&1; then
  echo -e "${RED}❌ SHARED_SIGNING_SECRET reference found outside environment loading flow!${NC}"
  SECRET_FOUND=1
fi

if [ $SECRET_FOUND -eq 1 ]; then
  echo -e "${RED}❌ Secrets scan failed! Hardcoded secrets found.${NC}"
  FAILED=1
else
  echo -e "${GREEN}✓ Secrets scan clean (no raw keys detected in client code).${NC}"
fi

# 7. Git status report
echo -e "\n${YELLOW}[7/7] Summarizing git status...${NC}"
git status -s
echo -e "${GREEN}✓ Git status printed.${NC}"

# Final Verdict
echo -e "\n${YELLOW}==================================================${NC}"
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🟢 MERGE SAFE - All release checks passed!${NC}"
  echo -e "${YELLOW}==================================================${NC}"
  exit 0
else
  echo -e "${RED}🔴 STOP EVERYTHING - One or more release checks failed!${NC}"
  echo -e "${YELLOW}==================================================${NC}"
  exit 1
fi
