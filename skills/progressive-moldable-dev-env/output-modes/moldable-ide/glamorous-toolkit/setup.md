# Glamorous Toolkit — Setup

Detect GT, install if missing, validate CLI.

## Detection

Check in order:
1. `~/.gt/GlamorousToolkit.app` (standard location)
2. `~/Downloads/GT-spike/GlamorousToolkit.app` (spike location)
3. `~/Downloads/GlamorousToolkit.app`

## Installation (if not found)

```bash
mkdir -p ~/.gt
cd ~/.gt
# Detect platform
ARCH=$(uname -m)
case "$ARCH" in
    arm64) URL="https://dl.feenk.com/gt/GlamorousToolkitOSXM1-release.zip" ;;
    x86_64)
        case "$(uname -s)" in
            Darwin) URL="https://dl.feenk.com/gt/GlamorousToolkitOSX64-release.zip" ;;
            Linux)  URL="https://dl.feenk.com/gt/GlamorousToolkitLinux64-release.zip" ;;
        esac ;;
esac
curl -L -o GlamorousToolkit.zip "$URL"
unzip -q GlamorousToolkit.zip
rm GlamorousToolkit.zip
```

## Validation — smoke test

```bash
cd ~/.gt && ./GlamorousToolkit.app/Contents/MacOS/GlamorousToolkit-cli GlamorousToolkit.image eval "3 + 4"
# Must output: 7
```

## macOS Gatekeeper

First launch: tell the user to right-click `GlamorousToolkit.app` > Open if prompted by Gatekeeper.

## Critical

The `.image` file MUST be at the same directory level as `.app`. Not inside it.
