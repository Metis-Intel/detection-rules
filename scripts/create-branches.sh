#!/bin/bash
# Script to create prod, stage, and dev branches from main
# This script assumes you're starting from the main branch

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Creating Environment Branches ===${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${NC}"
    echo "Initialize git first with: git init"
    exit 1
fi

# Get the default branch (main or master)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Check if main/master exists locally, if not try to fetch
if ! git show-ref --verify --quiet refs/heads/$DEFAULT_BRANCH; then
    echo -e "${YELLOW}Default branch '$DEFAULT_BRANCH' not found locally${NC}"
    echo "Fetching from remote..."
    git fetch origin 2>/dev/null || echo "No remote configured, will create from current branch"
    
    # Try to checkout main from remote
    if git show-ref --verify --quiet refs/remotes/origin/$DEFAULT_BRANCH; then
        git checkout -b $DEFAULT_BRANCH origin/$DEFAULT_BRANCH 2>/dev/null || true
    fi
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)

# If we're not on main, switch to it or create it
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    if git show-ref --verify --quiet refs/heads/$DEFAULT_BRANCH; then
        echo "Switching to $DEFAULT_BRANCH branch..."
        git checkout $DEFAULT_BRANCH
    else
        echo -e "${YELLOW}Creating $DEFAULT_BRANCH branch from current branch ($CURRENT_BRANCH)${NC}"
        git checkout -b $DEFAULT_BRANCH
    fi
fi

# Branches to create
BRANCHES=("dev" "stage" "prod")

echo "Creating branches from $DEFAULT_BRANCH:"
for BRANCH in "${BRANCHES[@]}"; do
    if git show-ref --verify --quiet refs/heads/$BRANCH; then
        echo -e "${YELLOW}  Branch '$BRANCH' already exists, skipping...${NC}"
    else
        echo "  Creating branch: $BRANCH"
        git checkout -b $BRANCH
        git checkout $DEFAULT_BRANCH
        echo -e "${GREEN}  ✓ Created branch: $BRANCH${NC}"
    fi
done

echo ""
echo -e "${GREEN}=== Branches Created Successfully ===${NC}"
echo ""
echo "Available branches:"
git branch -a
echo ""
echo "To push branches to remote:"
echo "  git push -u origin dev"
echo "  git push -u origin stage"
echo "  git push -u origin prod"

