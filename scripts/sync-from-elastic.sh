#!/bin/bash
# Sync rules from Elastic Security to GitHub repository
# This script can be used for local testing

set -e

# Configuration
CUSTOM_RULES_DIR="${CUSTOM_RULES_DIR:-custom_rules}"
EXPORT_DIR="${EXPORT_DIR:-elastic-export}"
KIBANA_URL="${DR_KIBANA_URL:-${ELASTIC_KIBANA_URL}}"
API_KEY="${DR_API_KEY:-${ELASTIC_API_KEY}}"
SPACE="${DR_SPACE:-default}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Syncing Rules from Elastic Security ===${NC}"
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

echo "Configuration:"
echo "  Custom Rules Directory: $CUSTOM_RULES_DIR"
echo "  Export Directory: $EXPORT_DIR"
echo "  Kibana URL: $KIBANA_URL"
echo "  Space: $SPACE"
echo ""

# Create directories
echo -e "${GREEN}Step 1: Creating directories...${NC}"
mkdir -p "$EXPORT_DIR"
mkdir -p "$CUSTOM_RULES_DIR/rules"
mkdir -p "$CUSTOM_RULES_DIR/exceptions"
mkdir -p "$CUSTOM_RULES_DIR/action_connectors"
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Export rules from Elastic
echo -e "${GREEN}Step 2: Exporting rules from Elastic...${NC}"
CUSTOM_RULES_DIR="$CUSTOM_RULES_DIR" \
python -m detection_rules kibana \
    --kibana-url "$KIBANA_URL" \
    --api-key "$API_KEY" \
    --space "$SPACE" \
    export-rules \
    -d "$EXPORT_DIR" \
    -cro \
    -e \
    -ac \
    -ed "$CUSTOM_RULES_DIR/exceptions" \
    -acd "$CUSTOM_RULES_DIR/action_connectors" \
    -s \
    -lu \
    -lc

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Rules exported successfully${NC}"
else
    echo -e "${YELLOW}⚠ Export completed with some errors (check logs)${NC}"
fi
echo ""

# Check if any rules were exported
if [ ! -d "$EXPORT_DIR" ] || [ -z "$(find "$EXPORT_DIR" -name '*.toml' -type f 2>/dev/null)" ]; then
    echo -e "${YELLOW}No rules found in export directory${NC}"
    echo "This could mean:"
    echo "  - No custom rules exist in Elastic"
    echo "  - Export failed (check errors above)"
    echo ""
    echo "Cleaning up..."
    rm -rf "$EXPORT_DIR"
    exit 0
fi

# Import rules to repository
echo -e "${GREEN}Step 3: Importing rules to repository...${NC}"
CUSTOM_RULES_DIR="$CUSTOM_RULES_DIR" \
python -m detection_rules import-rules-to-repo \
    -d "$EXPORT_DIR" \
    -s "$CUSTOM_RULES_DIR/rules" \
    -se "$CUSTOM_RULES_DIR/exceptions" \
    -sa "$CUSTOM_RULES_DIR/action_connectors" \
    -e \
    -ac \
    -ske \
    -da "Elastic Sync"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Rules imported successfully${NC}"
else
    echo -e "${YELLOW}⚠ Import completed with some errors (check logs)${NC}"
fi
echo ""

# Cleanup
echo -e "${GREEN}Step 4: Cleaning up...${NC}"
rm -rf "$EXPORT_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

echo -e "${GREEN}=== Sync Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes in $CUSTOM_RULES_DIR"
echo "  2. Test the imported rules: CUSTOM_RULES_DIR=$CUSTOM_RULES_DIR python -m detection_rules test"
echo "  3. Commit and push if the changes look good"

