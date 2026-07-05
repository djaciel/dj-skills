#!/usr/bin/env bash
# Install dj-skills (skills + agents) into Claude Code.
#
# Usage:
#   ./install.sh                     # user-level: ~/.claude (all projects)
#   ./install.sh /path/to/project    # project-level: <project>/.claude
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${1:-$HOME}"
TARGET="$BASE/.claude"

mkdir -p "$TARGET/skills" "$TARGET/agents"

# Skills: replace any previous copy or symlink with a fresh copy
for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "$TARGET/skills/$name"
  cp -R "$skill" "$TARGET/skills/$name"
done

# Agents: plain copy (the skills CLI does not manage these)
cp "$REPO_DIR"/agents/*.md "$TARGET/agents/"

echo "Installed $(find "$REPO_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skills  -> $TARGET/skills/"
echo "Installed $(ls "$REPO_DIR"/agents/*.md | wc -l | tr -d ' ') agents  -> $TARGET/agents/"
echo "Re-run this script after every 'git pull' or local edit."
