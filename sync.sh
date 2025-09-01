#!/usr/bin/env bash
set -e

WORKDIR="$(pwd)"
MANIFEST_FILE="$WORKDIR/.repo/manifest.xml"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "You are about to sync all repos into:"
  echo "  $WORKDIR"
  read -p "Are you sure you want to continue? [y/N] " confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi

  if ! command -v repo &> /dev/null; then
    echo "Installing repo tool..."
    curl https://storage.googleapis.com/git-repo-downloads/repo > repo
    chmod a+x repo
    sudo mv repo /usr/local/bin/
  fi

  echo "Initializing manifest..."
  repo init -u https://github.com/diskria/manifest.git -b main -m default.xml
else
  echo "Manifest already initialized, skipping repo init."
fi

echo "Checking for uncommitted changes..."
dirty_repos=$(repo forall -c '
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo $REPO_PATH
fi
')

if [[ -n "$dirty_repos" ]]; then
  echo "Found uncommitted changes in the following projects:"
  echo "$dirty_repos" | sed "s/^/ - /"
  echo "Please commit or stash them before syncing."
  exit 1
fi

echo "Syncing all repositories... this may take a while"
repo sync -j"$(nproc)"

echo "All repositories synced successfully!"
