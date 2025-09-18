# 🌈 Spectrum

[![Inspired by Google Repo](https://img.shields.io/badge/inspired%20by-Google%20Repo-blue)](https://gerrit.googlesource.com/git-repo)

A manifest repository that brings all projects together into a single AOSP-style tree.
Instead of managing repositories one by one, you can sync everything at once and always get a consistent project layout.

## Sync

Run this [one-liner](https://raw.githubusercontent.com/diskria/spectrum/main/sync.sh) to install `repo`, init the manifest and sync all repositories:

```bash
bash <(curl -s https://raw.githubusercontent.com/diskria/spectrum/main/sync.sh)
```

## Resulting structure

After syncing, you’ll have a consistent project tree, for example:

```bash
workspace/
├─ diskria/
│  ├─ diskria/
│  ├─ projektor/
│  └─ spectrum/
├─ organizationA/
│  └─ project1/
├─ organizationB/
│  └─ project2/
└─ organizationC/
   └─ project3/
```

## Why

* Keep all repositories under one roof
* Fixed and consistent paths across environments
* Simple local setup and navigation
* Perfect for cross-project development and quick context switching
