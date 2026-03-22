#!/bin/bash

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║         skills setup          ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
echo ""

# Collect available skills
skills=()
while IFS= read -r -d '' dir; do
  skill_name="$(basename "$dir")"
  if [ -f "$dir/SKILL.md" ]; then
    skills+=("$skill_name")
  fi
done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

if [ ${#skills[@]} -eq 0 ]; then
  echo -e "${RED}No skills found in $SKILLS_DIR${RESET}"
  exit 1
fi

# Step 1: Select skill
echo -e "${CYAN}Available skills:${RESET}"
for i in "${!skills[@]}"; do
  echo -e "  ${BOLD}$((i+1)).${RESET} ${skills[$i]}"
done
echo -e "  ${BOLD}0.${RESET} All"
echo ""
read -r -p "Select skill to install (0-${#skills[@]}): " skill_choice

selected_skills=()
if [ "$skill_choice" = "0" ]; then
  selected_skills=("${skills[@]}")
elif [[ "$skill_choice" =~ ^[0-9]+$ ]] && [ "$skill_choice" -ge 1 ] && [ "$skill_choice" -le "${#skills[@]}" ]; then
  selected_skills=("${skills[$((skill_choice-1))]}")
else
  echo -e "${RED}Invalid selection.${RESET}"
  exit 1
fi

# Step 2: Select install scope
echo ""
echo -e "${CYAN}Install location:${RESET}"
echo -e "  ${BOLD}1.${RESET} Global  (~/.claude/skills/)  — available in all projects"
echo -e "  ${BOLD}2.${RESET} Project (./.claude/skills/) — current project only"
echo ""
read -r -p "Select location (1/2): " scope_choice

case "$scope_choice" in
  1)
    TARGET_DIR="$HOME/.claude/skills"
    scope_label="global"
    ;;
  2)
    TARGET_DIR="$(pwd)/.claude/skills"
    scope_label="project"
    ;;
  *)
    echo -e "${RED}Invalid selection.${RESET}"
    exit 1
    ;;
esac

mkdir -p "$TARGET_DIR"

# Step 3: Install
echo ""
for skill in "${selected_skills[@]}"; do
  src="$SKILLS_DIR/$skill"
  dst="$TARGET_DIR/$skill"

  if [ -d "$dst" ]; then
    echo -e "${YELLOW}⚠ '$skill' already exists at $dst${RESET}"
    read -r -p "  Overwrite? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      echo -e "  Skipped."
      continue
    fi
    rm -rf "$dst"
  fi

  cp -r "$src" "$dst"
  echo -e "${GREEN}✓ Installed '$skill' → $dst ($scope_label)${RESET}"
done

echo ""
echo -e "${BOLD}Done.${RESET} Verify with ${CYAN}/skills${RESET} in Claude Code."
echo ""
