# DracoTableScripts

Shell scripts and Automator launchers for running and updating a custom darktable development build on macOS Apple Silicon.

This repository contains:
- a launcher script for starting the custom darktable build with dedicated config and cache directories
- an update/build script for fetching the latest changes, checking whether updates are available, and rebuilding only when needed
- external configuration files for keeping machine-specific paths out of the scripts

## Project structure

```text
DracoTableScripts/
├── DracoTable.app
├── DracoTable_CheckUpdate.app
├── src/
│   ├── DracoTable.sh
│   └── DracoTable_CheckUpdate.sh
├── Notes/
│   └── dtCheckUpdatesBashRawProcedure.txt
└── conf/
    ├── DracoTable.conf
    └── DracoTable_CheckUpdate.conf
```

## Components

### DracoTable
Launches the custom darktable development build with explicit environment variables, config directory, and cache directory.

### DracoTable_CheckUpdate
Checks the Git repository for updates, skips the build if the local branch is already up to date, and rebuilds/install darktable when new changes are available.

## Notes directory
folder containing development notes, such as notes or otherwise

## Configuration

All machine-specific paths are stored in external configuration files under `conf/`.

This keeps the shell scripts reusable and easier to maintain.

## Usage

- Launch `DracoTable.app` to start darktable
- Launch `DracoTable_CheckUpdate.app` to check for updates and rebuild if needed

## Notes

This project is intended for local macOS Apple Silicon usage with Homebrew-based dependencies and a custom darktable development installation.
