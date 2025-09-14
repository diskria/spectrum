#!/usr/bin/env bash
# shellcheck disable=SC2016

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

cmd="${1:-help}"

case "$cmd" in
  status)
    ./repo forall -c '
      GREEN="\033[0;32m"
      YELLOW="\033[0;33m"
      RED="\033[0;31m"
      RESET="\033[0m"

      status="clean"
      color=$GREEN

      if ! git diff --quiet || ! git diff --cached --quiet; then
        status="has uncommitted changes"
        color=$RED
      fi

      if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
        BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

        if [[ -n "$REMOTE" ]]; then
          if [[ $LOCAL = $REMOTE ]]; then
            :
          elif [[ $LOCAL = $BASE ]]; then
            status="is behind remote"
            color=$YELLOW
          elif [[ $REMOTE = $BASE ]]; then
            status="has unpushed commits"
            color=$YELLOW
          else
            status="diverged from remote"
            color=$RED
          fi
        fi
      fi

      printf "[${color}%s${RESET}] %s\n" "$REPO_PROJECT" "$status"
    '
    ;;

  update-gradle)
    if [ $# -lt 2 ]; then
      echo -e "${RED}Error:${RESET} Gradle version is required."
      echo "Usage: $0 update-gradle <version>"
      exit 1
    fi
    version="$2"
    ./repo forall -c "
      if [ -f gradlew ]; then
        ./gradlew wrapper --gradle-version=$version --distribution-type=all
        git add gradle/wrapper/ gradlew gradlew.bat
        if ! git diff --cached --quiet; then
          git commit -m 'Update Gradle wrapper to $version'
          echo '[OK] \$REPO_PROJECT gradle updated'
        else
          echo '[SKIP] \$REPO_PROJECT gradle already up-to-date'
        fi
      else
        echo '[SKIP] \$REPO_PROJECT has no Gradle wrapper'
      fi
    "
    ;;

  sync)
    if [ -x .repo/manifests/sync.sh ]; then
      .repo/manifests/sync.sh
    else
      echo -e "${RED}No sync script found at .repo/manifests/sync.sh${RESET}"
      exit 1
    fi
    ;;

  help|--help|-h|"")
    echo "Usage: $0 <command> [args...]"
    echo
    echo "Commands:"
    echo "  status             Show git status of all repos"
    echo "  update-gradle <v>  Update Gradle wrapper for all repos to new version"
    echo "  sync               Sync all repos"
    echo "  help               Show this help message"
    ;;

  *)
    echo -e "${RED}Unknown command:${RESET} $cmd"
    echo "Run '$0 help' for usage."
    exit 1
    ;;
esac
