# Spectrum

[![Inspired by Google Repo](https://img.shields.io/badge/inspired%20by-Google%20Repo-blue)](https://gerrit.googlesource.com/git-repo)

Repo manifest that glues all my projects into one AOSP-style tree.
Because why manage repos one by one when you can sync everything at once?

## Sync

Run this [one-liner](https://raw.githubusercontent.com/diskria/spectrum/main/sync.sh) to install `repo`, init the manifest and sync all repos:

```bash
bash <(curl -s https://raw.githubusercontent.com/diskria/spectrum/main/sync.sh)
```

The script will ask for confirmation before cloning into the current directory.

## Resulting structure

After syncing, you’ll have a consistent project tree, for example:

```bash
workspace/
 ├─ diskria
 ├─ spectrum # you are here btw
 ├─ projektor
 ├─ organizationA/project1
 ├─ organizationB/project2
 └─ organizationC/project3
```

## Why

* Keep all repos under one roof
* Easy local setup (AOSP-style workflow)
* Perfect for hacking across multiple projects at once
