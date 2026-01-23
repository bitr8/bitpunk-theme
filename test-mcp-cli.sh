#!/bin/bash
# Test script to compare MCP token usage with/without ENABLE_EXPERIMENTAL_MCP_CLI

set -e

PROMPT="List all MCP tools you have access to, then exit with /exit"
JOURNAL_DIR="$HOME/.claude/projects"
TIMESTAMP=$(date +%s)

echo "=== MCP-CLI Token Comparison Test ==="
echo ""

# Find the most recent journal before tests
get_latest_journal() {
    find "$JOURNAL_DIR" -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-
}

count_tool_definitions() {
    local journal="$1"
    if [[ -f "$journal" ]]; then
        # Count tool definitions in system prompt (rough estimate)
        grep -o '"name":\s*"mcp__' "$journal" 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

get_journal_size() {
    local journal="$1"
    if [[ -f "$journal" ]]; then
        stat --printf="%s" "$journal" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

echo "Step 1: Run WITHOUT experimental flag"
echo "--------------------------------------"
echo "Run this command in a new terminal:"
echo ""
echo "  claude --print-system-prompt 2>/dev/null | wc -c"
echo ""
echo "Note the character count, then press Enter to continue..."
read -r

echo ""
echo "Characters WITHOUT flag: "
read -r chars_without

echo ""
echo "Step 2: Run WITH experimental flag"
echo "-----------------------------------"
echo "Run this command in a new terminal:"
echo ""
echo "  ENABLE_EXPERIMENTAL_MCP_CLI=true claude --print-system-prompt 2>/dev/null | wc -c"
echo ""
echo "Note the character count, then press Enter to continue..."
read -r

echo ""
echo "Characters WITH flag: "
read -r chars_with

echo ""
echo "=== Results ==="
echo "Without ENABLE_EXPERIMENTAL_MCP_CLI: $chars_without chars"
echo "With ENABLE_EXPERIMENTAL_MCP_CLI:    $chars_with chars"

if [[ "$chars_without" -gt 0 && "$chars_with" -gt 0 ]]; then
    reduction=$(( (chars_without - chars_with) * 100 / chars_without ))
    echo ""
    echo "Reduction: ${reduction}%"
    echo "Saved: $((chars_without - chars_with)) characters in system prompt"
fi
