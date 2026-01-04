# Steam CSS Patcher (Linux)

A simple, interactive Bash script for customising the Steam client UI on Linux by patching Steam’s compiled CSS files.

I prefer a minimalist aesthetic, and one day became annoyed by the subjective bloat on Steam's Library page. I came across a Powershell script by xtcrefugee and decided to adapt it so that I could use it on Linux. I threw it into an AI server I had built and decided to vibecode it into an interactive script.  This is the result.

This script allows you to:
- Hide the 'What’s New' section
- Remove the 'Add Shelf' feature
- Hide the Left Column
- Safely backup, restore, and clean up CSS changes

Make sure to keep a backup of the original. On my Arch system it can be found here:

    ~/.steam/steam/steamui/css/chunk~2dcc5aaf7.css

---

## Features

- Interactive menu-driven interface
- Automatic detection of the active css file
- Optional backups before patching
- The first run creates a hidden backup file in the Steam CSS file folder to allow the user to restore this CSS file as an original backup.
- Selective enable/disable of the Steam Library page UI elements. Each CSS change is optional and confirmed interactively.
- Restore from a previous backup
- Ensures Steam is not running before modifying files
- Writes changes to a temporary file and only replaces the original if changes were made

---

## Requirements

- Linux
- Bash
- Steam - System or Flatpak (only tested on System)

---

## Installation

Clone the repository:

    git clone https://github.com/yourusername/steam-css-patcher-linux.git
    cd steam-css-patcher-linux

Make the script executable:

    chmod +x steam-css-patcher-linux.sh

---

## Usage

Run the script in your preferred Linux terminal:

    ./steam-css-patcher-linux.sh

### Main Menu Options

- Apply CSS changes
- Reverse CSS changes
- Restore from backup
- Clean old backups
- Restore CSS to native defaults
- Quit

---

## Backups

- Backups are stored alongside the CSS file
- Each backup includes a timestamp in the menu
- You can restore or delete backups from within the script
- 

---

## Important Notes

- Steam updates may overwrite patched CSS files, so you may need to re-run the script after Steam updates if the Library UI reverts back to the Steam default
- This script relies on exact CSS matches — if Steam changes class names, patches may stop working
- Always keep at least one backup

---

## License

GPLv3

[LICENSE](LICENSE)

---

## Disclaimer

This project is not affiliated with Valve or Steam.  
All trademarks belong to their respective owners.

---

Original inspiration came from the original PowerShell script by xtcrefugee:
https://github.com/xtcrefugee


⚠️ Use at your own risk — Steam updates may overwrite CSS files at any time.
