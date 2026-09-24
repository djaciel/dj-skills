#!/usr/bin/env bash
# Install dj-skills (skills + agents + scripts) into Claude Code.
#
# Usage:
#   ./install.sh                     # user-level: ~/.claude (all projects)
#   ./install.sh /path/to/project    # project-level: <project>/.claude
#
# Scripts land in <target>/scripts/dj/: ~/.claude/scripts/dj/ for a user-level
# install, <project>/.claude/scripts/dj/ for a project-level one. Plain bash.
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

# Scripts: replace the dj/ folder with a fresh, executable copy
rm -rf "$TARGET/scripts/dj"
mkdir -p "$TARGET/scripts/dj"
cp "$REPO_DIR"/scripts/* "$TARGET/scripts/dj/"
chmod +x "$TARGET"/scripts/dj/*

echo "Installed $(find "$REPO_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skills  -> $TARGET/skills/"
echo "Installed $(ls "$REPO_DIR"/agents/*.md | wc -l | tr -d ' ') agents  -> $TARGET/agents/"
echo "Installed $(ls "$REPO_DIR"/scripts | wc -l | tr -d ' ') scripts -> $TARGET/scripts/dj/"
echo "Re-run this script after every 'git pull' or local edit."
