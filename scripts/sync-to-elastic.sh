#!/bin/bash
# Sync rules from GitHub repository to Elastic Security
# This script can be used for local testing before pushing to GitHub

set -e

# Configuration
CUSTOM_RULES_DIR="${CUSTOM_RULES_DIR:-custom_rules}"
KIBANA_URL="${DR_KIBANA_URL:-${ELASTIC_KIBANA_URL}}"
API_KEY="${DR_API_KEY:-${ELASTIC_API_KEY}}"
SPACE="${DR_SPACE:-default}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Syncing Rules to Elastic Security ===${NC}"
echo ""

# Check if required variables are set
if [ -z "$KIBANA_URL" ]; then
    echo -e "${RED}Error: KIBANA_URL or DR_KIBANA_URL environment variable is not set${NC}"
    echo "Set it with: export DR_KIBANA_URL=https://sub.metis.us.com"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: API_KEY or DR_API_KEY environment variable is not set${NC}"
    echo "Set it with: export DR_API_KEY=your-api-key-here"
    exit 1
fi

# Check if custom rules directory exists
if [ ! -d "$CUSTOM_RULES_DIR" ]; then
    echo -e "${YELLOW}Warning: Custom rules directory '$CUSTOM_RULES_DIR' does not exist${NC}"
    echo "Creating directory..."
    mkdir -p "$CUSTOM_RULES_DIR/rules"
    mkdir -p "$CUSTOM_RULES_DIR/exceptions"
    mkdir -p "$CUSTOM_RULES_DIR/action_connectors"
fi

# Check if there are any rules to sync
if [ ! -d "$CUSTOM_RULES_DIR/rules" ] || [ -z "$(find "$CUSTOM_RULES_DIR/rules" -name '*.toml' -type f 2>/dev/null)" ]; then
    echo -e "${YELLOW}Warning: No TOML rule files found in $CUSTOM_RULES_DIR/rules${NC}"
    echo "Skipping sync..."
    exit 0
fi

echo "Configuration:"
echo "  Custom Rules Directory: $CUSTOM_RULES_DIR"
echo "  Kibana URL: $KIBANA_URL"
echo "  Space: $SPACE"
echo ""

# Validate rules first
echo -e "${GREEN}Step 1: Validating rules...${NC}"
if CUSTOM_RULES_DIR="$CUSTOM_RULES_DIR" python -m detection_rules test; then
    echo -e "${GREEN}✓ Rules validation passed${NC}"
else
    echo -e "${YELLOW}⚠ Some validation tests failed, but continuing...${NC}"
fi
echo ""

# Sync rules
echo -e "${GREEN}Step 2: Syncing rules to Elastic...${NC}"
CUSTOM_RULES_DIR="$CUSTOM_RULES_DIR" \
python -m detection_rules kibana \
    --kibana-url "$KIBANA_URL" \
    --api-key "$API_KEY" \
    --space "$SPACE" \
    import-rules \
    -d "$CUSTOM_RULES_DIR/rules" \
    -o \
    -e \
    -ac

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Rules synced successfully${NC}"
else
    echo -e "${RED}✗ Failed to sync rules${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Sync Complete ===${NC}"

