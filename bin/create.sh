#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"

# ── Helpers ──────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") <project-name> [target-directory]

Generate a new React project from the vibe-scaffolding template.

Arguments:
  project-name       Project name in kebab-case (e.g. my-cool-app)
  target-directory   Where to create the project (default: ./<project-name>)

Options:
  -h, --help         Show this help message
  --no-install       Skip npm install
  --no-git           Skip git init

Examples:
  $(basename "$0") my-app
  $(basename "$0") my-app ./projects/my-app
  $(basename "$0") my-app --no-install
EOF
  exit 0
}

to_title() {
  echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# ── Parse arguments ──────────────────────────────────────────────────────────

NO_INSTALL=false
NO_GIT=false
PROJECT_NAME=""
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --no-install) NO_INSTALL=true; shift ;;
    --no-git) NO_GIT=true; shift ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      echo "Run '$(basename "$0") --help' for usage." >&2
      exit 1
      ;;
    *)
      if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="$1"
      elif [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
      else
        echo "Error: Too many arguments." >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: project-name is required." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
fi

# Validate kebab-case
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
  echo "Error: project-name must be kebab-case (e.g. my-cool-app)." >&2
  exit 1
fi

TARGET_DIR="${TARGET_DIR:-$PROJECT_NAME}"
PROJECT_TITLE="$(to_title "$PROJECT_NAME")"

# ── Pre-checks ───────────────────────────────────────────────────────────────

if [[ -e "$TARGET_DIR" ]]; then
  echo "Error: '$TARGET_DIR' already exists." >&2
  exit 1
fi

# ── Copy template ────────────────────────────────────────────────────────────

echo "Creating project '$PROJECT_NAME' in $TARGET_DIR ..."

mkdir -p "$TARGET_DIR"

# Files and directories to exclude from the generated project
rsync -a \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='bin' \
  --exclude='.claude' \
  --exclude='coverage' \
  --exclude='playwright-report' \
  --exclude='test-results' \
  "$TEMPLATE_DIR/" "$TARGET_DIR/"

# ── Replace placeholders ────────────────────────────────────────────────────

echo "Configuring project name ..."

# Collect all text files to process (skip binaries, images, lock files)
find "$TARGET_DIR" -type f \
  \( -name '*.ts' -o -name '*.tsx' -o -name '*.json' -o -name '*.md' \
     -o -name '*.html' -o -name '*.css' -o -name '*.yml' -o -name '*.yaml' \
     -o -name '*.env*' -o -name 'Makefile' -o -name 'Dockerfile' \
     -o -name '.prettierrc' -o -name '.dockerignore' -o -name '.gitignore' \
     -o -name '.prettierignore' \) \
  ! -path '*/node_modules/*' \
  ! -name 'package-lock.json' \
  -print0 | while IFS= read -r -d '' file; do
    # Order matters: replace the title form first, then the kebab-case form
    if grep -q 'Vibe Scaffolding\|vibe-scaffolding\|vibe-app' "$file" 2>/dev/null; then
      sed -i '' \
        -e "s/Vibe Scaffolding/$PROJECT_TITLE/g" \
        -e "s/vibe-scaffolding/$PROJECT_NAME/g" \
        -e "s/vibe-app/$PROJECT_NAME/g" \
        "$file"
    fi
  done

# ── Initialize git ───────────────────────────────────────────────────────────

if [[ "$NO_GIT" == false ]]; then
  echo "Initializing git repository ..."
  (cd "$TARGET_DIR" && git init -q && git add -A && git commit -q -m "Initial commit from vibe-scaffolding")
fi

# ── Install dependencies ────────────────────────────────────────────────────

if [[ "$NO_INSTALL" == false ]]; then
  echo "Installing dependencies ..."
  (cd "$TARGET_DIR" && npm install --silent)
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Done! Your project is ready at $TARGET_DIR"
echo ""
echo "  cd $TARGET_DIR"
echo "  make dev"
echo ""
