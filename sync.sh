#!/usr/bin/env bash
# shellcheck disable=SC2016 # repo forall expands variables inside single quotes

set -euo pipefail

WORKDIR="$(pwd)"

if [ -n "$(ls -A "$WORKDIR")" ]; then
  echo "Please run this script in an empty directory."
  exit 1
fi

echo "You are about to sync all repos into:"
echo "  $WORKDIR"
read -r -p "Are you sure you want to continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

if ! git config --global color.ui >/dev/null; then
  git config --global color.ui false
fi

if ! command -v repo &> /dev/null; then
  echo "Installing repo tool..."
  curl -s https://storage.googleapis.com/git-repo-downloads/repo > repo
  chmod a+x "$WORKDIR/repo"
fi

PATH="$WORKDIR:$PATH"

if [ ! -d "$WORKDIR/.repo" ]; then
  echo "Initializing manifest..."
  repo init -q -u https://github.com/diskria/spectrum.git --manifest-depth=1
else
  dirty_projects=$(repo forall -c '
    if ! git diff --quiet || ! git diff --cached --quiet; then
      echo "$REPO_PROJECT"
    fi
  ')
  if [[ -n "$dirty_projects" ]]; then
    echo "Found uncommitted changes in the following projects:"
    echo "$dirty_projects"

    read -r -p "Do you want to auto-push them? [y/N] " autopush
    if [[ "$autopush" =~ ^[Yy]$ ]]; then
      repo forall -c '
        if ! git diff --quiet || ! git diff --cached --quiet; then
          echo "[$REPO_PROJECT] pushing..."
          git fetch origin || { echo "[$REPO_PROJECT] fetch failed"; exit 1; }
          git commit -m "chore: sync repo" || echo "[$REPO_PROJECT] nothing to commit"
          if ! git merge --no-edit origin/$(git rev-parse --abbrev-ref HEAD); then
            echo "[$REPO_PROJECT] merge conflict! Please resolve manually."
            exit 1
          fi
          git push origin HEAD || { echo "[$REPO_PROJECT] push failed"; exit 1; }
        fi
      '
    else
      echo "Aborted due to uncommitted changes."
      exit 1
    fi
  fi
fi

echo "Syncing all repositories..."
repo sync -j"$(nproc)" --fail-fast --current-branch --no-tags -q --this-manifest-only
repo forall -c 'git checkout -q -B "$REPO_RREV" "origin/$REPO_RREV"'
repo forall -c '
  if [ -f .gitmodules ]; then
    echo "Updating submodules in $REPO_PROJECT..."
    git submodule --quiet update --init --depth=1
  fi
'
echo "All repositories synced successfully!"

if [ ! -d "$WORKDIR/.env" ]; then
  read -r -p "Do you want to create a Python virtual environment in $WORKDIR/.env? [y/N] " setup_env
  if [[ "$setup_env" =~ ^[Yy]$ ]]; then
    if ! command -v python3 &> /dev/null; then
      echo "Python 3.x is required but not installed. Please install it manually."
      exit 1
    fi
    echo "Creating Python virtual environment..."
    python3 -m venv "$WORKDIR/.env" || {
      echo "Failed to create virtual environment. Exiting."
      exit 1
    }
    echo "Virtual environment created at $WORKDIR/.env"
  fi
fi

if [ -f "$WORKDIR/.repo/manifests/spectrum.sh" ] && [ ! -f "$WORKDIR/spectrum.sh" ]; then
  cp "$WORKDIR/.repo/manifests/spectrum.sh" "$WORKDIR/spectrum.sh"
  chmod +x "$WORKDIR/spectrum.sh"
  echo "The spectrum tool has been installed as ./spectrum.sh"
  echo "Run './spectrum.sh help' to see available commands."
fi
