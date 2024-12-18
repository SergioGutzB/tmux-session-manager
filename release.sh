#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Helper functions
log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() {
  echo -e "${RED}[✗]${NC} $1"
  exit 1
}

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  error "Not a git repository. Please run this script from the root of your git project."
fi

# Ensure working directory is clean
if ! git diff-index --quiet HEAD --; then
  error "Working directory not clean. Please commit or stash changes first."
fi

# Get the current version from the latest tag
current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
current_version=${current_version#v}

# Function to increment version
increment_version() {
  local version=$1
  local part=$2

  IFS='.' read -r -a parts <<<"$version"
  local major="${parts[0]}"
  local minor="${parts[1]}"
  local patch="${parts[2]}"

  case $part in
  major) echo "$((major + 1)).0.0" ;;
  minor) echo "${major}.$((minor + 1)).0" ;;
  patch) echo "${major}.${minor}.$((patch + 1))" ;;
  esac
}

# Ask for version type
echo "Current version is: v${current_version}"
echo "What kind of release is this?"
echo "1) Major (Breaking changes)"
echo "2) Minor (New features)"
echo "3) Patch (Bug fixes)"
read -p "Select an option [1-3]: " version_type

case $version_type in
1) new_version=$(increment_version "$current_version" "major") ;;
2) new_version=$(increment_version "$current_version" "minor") ;;
3) new_version=$(increment_version "$current_version" "patch") ;;
*) error "Invalid option selected" ;;
esac

# Confirm version
echo
echo "New version will be: v${new_version}"
read -p "Continue? [y/N] " confirm
if [[ $confirm != [yY] ]]; then
  error "Release cancelled by user"
fi

# Get release notes
echo
echo "Enter release notes (press Ctrl+D when done):"
release_notes=$(cat)

# Update CHANGELOG.md
changelog_entry="## [${new_version}] - $(date +%Y-%m-%d)\n${release_notes}\n"

if [ -f CHANGELOG.md ]; then
  # Create temporary file
  temp_file=$(mktemp)

  # Add header if file is empty
  if [ ! -s CHANGELOG.md ]; then
    echo "# Changelog" >"$temp_file"
    echo "" >>"$temp_file"
  else
    # Copy existing content
    cp CHANGELOG.md "$temp_file"
  fi

  # Find the position after the header
  header_line=$(grep -n "# Changelog" "$temp_file" | cut -d: -f1)
  if [ -n "$header_line" ]; then
    # Split the file and insert new entry
    head -n "$header_line" "$temp_file" >CHANGELOG.md
    echo "" >>CHANGELOG.md
    echo -e "$changelog_entry" >>CHANGELOG.md
    tail -n +$((header_line + 1)) "$temp_file" >>CHANGELOG.md
  else
    # If no header found, add it with the new entry
    echo "# Changelog" >CHANGELOG.md
    echo "" >>CHANGELOG.md
    echo -e "$changelog_entry" >>CHANGELOG.md
    cat "$temp_file" >>CHANGELOG.md
  fi

  # Clean up
  rm "$temp_file"
else
  # Create new CHANGELOG.md
  echo "# Changelog" >CHANGELOG.md
  echo "" >>CHANGELOG.md
  echo -e "$changelog_entry" >>CHANGELOG.md
fi

# Commit changes
log "Committing CHANGELOG updates"
git add CHANGELOG.md
git commit -m "Release version ${new_version}"

# Create and push tag
log "Creating release tag v${new_version}"
git tag -a "v${new_version}" -m "Release version ${new_version}

${release_notes}"

# Push changes
log "Pushing changes to remote"
git push origin main
git push origin "v${new_version}"

# Create GitHub release if gh CLI is installed
if command -v gh &>/dev/null; then
  log "Creating GitHub release"
  echo "${release_notes}" | gh release create "v${new_version}" \
    --title "Release v${new_version}" \
    --notes-file -
else
  warn "GitHub CLI not installed. To create release on GitHub:"
  echo "1. Go to: https://github.com/your-username/tmux-session-manager/releases/new"
  echo "2. Select tag: v${new_version}"
  echo "3. Set title as: Release v${new_version}"
  echo "4. Copy the release notes from CHANGELOG.md"
fi

log "Release v${new_version} completed successfully!"
