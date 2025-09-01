#!/usr/bin/env bash
set -e

WORKDIR="$(pwd)"

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
repo init -u https://github.com/diskria/manifest.git -b main

echo "Syncing all repositories... this may take a while"
repo sync -j"$(nproc)"

echo "All repositories synced successfully!"
